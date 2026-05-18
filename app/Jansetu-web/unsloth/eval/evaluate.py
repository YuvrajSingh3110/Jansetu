#!/usr/bin/env python3
"""
Jansetu E4B Evaluation Script
==============================
Compares base model vs fine-tuned model on the eval dataset.
Computes JSON parse rate, symptom precision/recall, referral recall,
severity accuracy, age group accuracy, and per-language-category breakdown.

Usage:
    # Compare base model vs fine-tuned:
    python evaluate.py \
        --base-model google/gemma-4-e4b-it \
        --finetuned-model ../train/outputs/jansetu-e4b-final

    # Eval fine-tuned only (no base comparison):
    python evaluate.py --finetuned-model ../train/outputs/jansetu-e4b-final

    # Just validate the eval JSONL (no model needed):
    python evaluate.py --dataset-only
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any

SYSTEM_PROMPT = (
    "You are Jansetu, a health AI assistant for rural India. "
    "When a user describes symptoms, extract them into a structured JSON object "
    "with these exact fields: symptoms (array of strings from the canonical list), "
    "duration (integer days or null), ageGroup (child/adult/elderly), "
    "gender (M/F/unknown), severity (mild/moderate/severe), referral (boolean). "
    "Canonical symptoms: fever, cough, breathlessness, diarrhoea, vomiting, rash, "
    "headache, bodyache, sore_throat, runny_nose, malnutrition, jaundice, "
    "conjunctivitis, seizure, unconscious, bleeding. "
    "Output ONLY the JSON object, nothing else."
)

RESULTS_PATH = Path(__file__).parent / "results.json"
EVAL_JSONL   = Path(__file__).parent.parent / "dataset" / "jansetu_symptoms_eval.jsonl"


# ---------------------------------------------------------------------------
# Metric helpers
# ---------------------------------------------------------------------------

def parse_output(text: str) -> dict | None:
    """Try to parse model output as JSON. Return None on failure."""
    text = text.strip()
    # strip markdown code fence if present
    if text.startswith("```"):
        lines = text.split("\n")
        text = "\n".join(lines[1:-1]) if len(lines) > 2 else text
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return None


def symptom_f1(gold: list[str], pred: list[str]) -> tuple[float, float]:
    """Return (precision, recall) for symptom lists."""
    if not gold:
        return (1.0, 1.0) if not pred else (0.0, 1.0)
    if not pred:
        return (1.0, 0.0)
    gold_set = set(gold)
    pred_set = set(pred)
    tp = len(gold_set & pred_set)
    precision = tp / len(pred_set)
    recall    = tp / len(gold_set)
    return precision, recall


def evaluate_examples(
    examples: list[dict[str, Any]],
    predictions: list[str],
) -> dict[str, Any]:
    """
    Compute all metrics given gold examples and raw model output strings.

    Returns a metrics dict with per-category breakdowns.
    """
    total = len(examples)
    parse_ok = 0
    sym_prec_sum = sym_rec_sum = 0.0
    ref_true_total = ref_true_correct = 0
    severity_correct = age_correct = 0

    category_scores: dict[str, dict[str, list[float]]] = {}

    for ex, pred_str in zip(examples, predictions):
        gold_out = json.loads(ex["messages"][2]["content"])
        cat = ex.get("category", "unknown")

        if cat not in category_scores:
            category_scores[cat] = {"parse": [], "sym_f1": [], "ref": [], "sev": [], "age": []}

        pred = parse_output(pred_str)
        if pred is None:
            category_scores[cat]["parse"].append(0.0)
            category_scores[cat]["sym_f1"].append(0.0)
            category_scores[cat]["ref"].append(0.0)
            category_scores[cat]["sev"].append(0.0)
            category_scores[cat]["age"].append(0.0)
            if gold_out["referral"]:
                ref_true_total += 1
            continue

        parse_ok += 1
        category_scores[cat]["parse"].append(1.0)

        prec, rec = symptom_f1(
            gold_out.get("symptoms", []),
            pred.get("symptoms", []),
        )
        sym_prec_sum += prec
        sym_rec_sum  += rec
        f1 = 2 * prec * rec / (prec + rec) if (prec + rec) > 0 else 0.0
        category_scores[cat]["sym_f1"].append(f1)

        if gold_out["referral"]:
            ref_true_total += 1
            correct_ref = int(pred.get("referral") is True)
            ref_true_correct += correct_ref
            category_scores[cat]["ref"].append(float(correct_ref))
        else:
            category_scores[cat]["ref"].append(-1.0)  # -1 = not applicable

        sev_ok = int(pred.get("severity") == gold_out["severity"])
        severity_correct += sev_ok
        category_scores[cat]["sev"].append(float(sev_ok))

        age_ok = int(pred.get("ageGroup") == gold_out["ageGroup"])
        age_correct += age_ok
        category_scores[cat]["age"].append(float(age_ok))

    json_parse_rate    = parse_ok / total
    sym_recall         = sym_rec_sum  / total
    sym_precision      = sym_prec_sum / total
    referral_recall    = ref_true_correct / max(ref_true_total, 1)
    severity_accuracy  = severity_correct / total
    age_accuracy       = age_correct / total

    # Per-category: average sym_f1 for positive+negative, referral_recall for ref cases only
    per_cat: dict[str, float] = {}
    for cat, scores in category_scores.items():
        sym_f1_vals = scores["sym_f1"]
        per_cat[cat] = sum(sym_f1_vals) / max(len(sym_f1_vals), 1)

    return {
        "json_parse_rate":   json_parse_rate,
        "symptom_recall":    sym_recall,
        "symptom_precision": sym_precision,
        "referral_recall":   referral_recall,
        "severity_accuracy": severity_accuracy,
        "age_accuracy":      age_accuracy,
        "per_category":      per_cat,
        "n_total":           total,
        "n_parse_ok":        parse_ok,
        "n_referral_true":   ref_true_total,
    }


# ---------------------------------------------------------------------------
# Model inference
# ---------------------------------------------------------------------------

def run_inference(
    model_name_or_path: str,
    examples: list[dict[str, Any]],
    is_finetuned: bool = False,
) -> list[str]:
    """
    Run inference for all examples using Unsloth FastModel.
    Returns a list of raw model output strings.
    """
    try:
        from unsloth import FastModel
    except ImportError:
        print("ERROR: Unsloth not installed. pip install unsloth")
        sys.exit(1)

    import torch

    print(f"\nLoading {'fine-tuned' if is_finetuned else 'base'} model: {model_name_or_path}")
    model, tokenizer = FastModel.from_pretrained(
        model_name=model_name_or_path,
        max_seq_length=512,
        load_in_4bit=True,
        dtype=None,
    )
    if is_finetuned:
        FastModel.for_inference(model)

    predictions: list[str] = []
    for i, ex in enumerate(examples):
        if i % 10 == 0:
            print(f"  Inference: {i}/{len(examples)} …", end="\r")

        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user",   "content": ex["messages"][1]["content"]},
        ]
        input_ids = tokenizer.apply_chat_template(
            messages,
            tokenize=True,
            add_generation_prompt=True,
            return_tensors="pt",
        ).to("cuda" if torch.cuda.is_available() else "cpu")

        with torch.no_grad():
            output_ids = model.generate(
                input_ids,
                max_new_tokens=150,
                temperature=0.1,
                do_sample=False,
                pad_token_id=tokenizer.eos_token_id,
            )
        # Only decode the newly generated tokens
        new_ids = output_ids[0][input_ids.shape[1]:]
        predictions.append(tokenizer.decode(new_ids, skip_special_tokens=True))

    print(f"  Inference: {len(examples)}/{len(examples)} done.           ")
    return predictions


# ---------------------------------------------------------------------------
# Pretty-print results table
# ---------------------------------------------------------------------------

def print_results_table(
    base_metrics: dict[str, Any] | None,
    ft_metrics: dict[str, Any],
) -> None:
    """Print a formatted comparison table to stdout."""
    print("\n" + "="*55)
    print("  JANSETU E4B FINE-TUNE EVALUATION")
    if base_metrics:
        print("  Base model vs Fine-tuned model comparison")
    print("="*55)

    def pct(v: float) -> str:
        return f"{v*100:.1f}%"

    def delta(b: float, f: float) -> str:
        d = (f - b) * 100
        sign = "+" if d >= 0 else ""
        return f"{sign}{d:.1f}%"

    rows = [
        ("JSON parse rate",    "json_parse_rate"),
        ("Symptom recall",     "symptom_recall"),
        ("Symptom precision",  "symptom_precision"),
        ("Referral recall",    "referral_recall"),
        ("Severity accuracy",  "severity_accuracy"),
        ("Age group accuracy", "age_accuracy"),
    ]

    if base_metrics:
        header = f"{'Metric':<22} {'Base':>8} {'Fine-tuned':>12} {'Delta':>8}"
        sep    = "─" * 52
        print(f"\n{header}")
        print(sep)
        for label, key in rows:
            b = base_metrics[key]
            f = ft_metrics[key]
            marker = "  ← critical" if key == "referral_recall" else ""
            print(f"  {label:<20} {pct(b):>8} {pct(f):>12} {delta(b,f):>8}{marker}")
    else:
        header = f"{'Metric':<22} {'Fine-tuned':>12}"
        sep    = "─" * 36
        print(f"\n{header}")
        print(sep)
        for label, key in rows:
            f = ft_metrics[key]
            marker = "  ← critical" if key == "referral_recall" else ""
            print(f"  {label:<20} {pct(f):>12}{marker}")

    print(f"\nPer-language breakdown (fine-tuned model):")
    cat_order = [
        "standard_hindi", "bhojpuri", "hinglish", "asha_clinical",
        "severe_emergency", "mild_cases", "elderly", "child_malnutrition",
    ]
    cat_labels = {
        "standard_hindi":     "Standard Hindi",
        "bhojpuri":           "Bhojpuri",
        "hinglish":           "Hinglish",
        "asha_clinical":      "ASHA clinical",
        "severe_emergency":   "Severe/emergency",
        "mild_cases":         "Mild cases",
        "elderly":            "Elderly",
        "child_malnutrition": "Child malnutrition",
    }
    for key in cat_order:
        if key in ft_metrics["per_category"]:
            score = ft_metrics["per_category"][key]
            label = cat_labels.get(key, key)
            print(f"  {label:<26} {pct(score):>8}")

    print(f"\n  Evaluated on {ft_metrics['n_total']} examples "
          f"({ft_metrics['n_referral_true']} referral=true cases)")
    print("="*55)


# ---------------------------------------------------------------------------
# Mock inference for --dataset-only mode
# ---------------------------------------------------------------------------

def gold_predictions(examples: list[dict[str, Any]]) -> list[str]:
    """Return the gold labels as 'predictions' — gives 100% accuracy baseline."""
    return [ex["messages"][2]["content"] for ex in examples]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def load_eval_examples() -> list[dict[str, Any]]:
    if not EVAL_JSONL.exists():
        print(f"ERROR: Eval dataset not found: {EVAL_JSONL}")
        print("  Fix: run  python dataset/generate_dataset.py  first.")
        sys.exit(1)
    with EVAL_JSONL.open(encoding="utf-8") as fh:
        return [json.loads(line) for line in fh if line.strip()]


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate Jansetu E4B fine-tune")
    parser.add_argument("--base-model",      default=None,
                        help="Base model name (e.g. google/gemma-4-e4b-it)")
    parser.add_argument("--finetuned-model", default=None,
                        help="Path to fine-tuned model directory")
    parser.add_argument("--dataset-only", action="store_true",
                        help="Skip inference; just validate dataset and show gold stats")
    args = parser.parse_args()

    if not args.dataset_only and args.finetuned_model is None:
        parser.error("Provide --finetuned-model or use --dataset-only")

    print("="*55)
    print("  JANSETU E4B EVALUATION")
    print("="*55)

    examples = load_eval_examples()
    print(f"\nEval examples loaded: {len(examples)}")

    if args.dataset_only:
        print("Dataset-only mode: using gold labels as predictions (sanity check).")
        ft_preds = gold_predictions(examples)
        ft_metrics  = evaluate_examples(examples, ft_preds)
        print_results_table(None, ft_metrics)
        return

    ft_preds   = run_inference(args.finetuned_model, examples, is_finetuned=True)
    ft_metrics = evaluate_examples(examples, ft_preds)

    base_metrics = None
    if args.base_model:
        base_preds   = run_inference(args.base_model, examples, is_finetuned=False)
        base_metrics = evaluate_examples(examples, base_preds)

    print_results_table(base_metrics, ft_metrics)

    # Save results
    results = {
        "finetuned": ft_metrics,
        "base": base_metrics,
    }
    RESULTS_PATH.write_text(json.dumps(results, indent=2, ensure_ascii=False))
    print(f"\nResults saved to: {RESULTS_PATH}")


if __name__ == "__main__":
    main()
