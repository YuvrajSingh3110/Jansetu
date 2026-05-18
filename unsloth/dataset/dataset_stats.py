#!/usr/bin/env python3
"""
Dataset Statistics Viewer
=========================
Load generated JSONL files and print detailed statistics.
Useful for verifying the dataset after running generate_dataset.py.

Run:
    python dataset_stats.py
    python dataset_stats.py --train jansetu_symptoms_train.jsonl
"""

import argparse
import json
from collections import Counter
from pathlib import Path

CANONICAL_SYMPTOMS = [
    "fever", "cough", "breathlessness", "diarrhoea", "vomiting",
    "rash", "headache", "bodyache", "sore_throat", "runny_nose",
    "malnutrition", "jaundice", "conjunctivitis", "seizure",
    "unconscious", "bleeding",
]


def load_jsonl(path: Path) -> list[dict]:
    with path.open(encoding="utf-8") as fh:
        return [json.loads(line) for line in fh if line.strip()]


def print_stats(examples: list[dict], label: str) -> None:
    total = len(examples)
    if total == 0:
        print(f"{label}: empty file")
        return

    referral_cnt:  Counter[bool] = Counter()
    severity_cnt:  Counter[str]  = Counter()
    symptom_cnt:   Counter[str]  = Counter()
    category_cnt:  Counter[str]  = Counter()
    age_group_cnt: Counter[str]  = Counter()
    gender_cnt:    Counter[str]  = Counter()
    duration_vals: list[int]     = []
    sym_per_ex:    list[int]     = []

    for ex in examples:
        out = json.loads(ex["messages"][2]["content"])
        referral_cnt[out["referral"]] += 1
        severity_cnt[out["severity"]] += 1
        age_group_cnt[out["ageGroup"]] += 1
        gender_cnt[out["gender"]] += 1
        category_cnt[ex.get("category", "unknown")] += 1
        for s in out["symptoms"]:
            symptom_cnt[s] += 1
        sym_per_ex.append(len(out["symptoms"]))
        if out["duration"] is not None:
            duration_vals.append(out["duration"])

    width = 58
    print(f"\n{'='*width}")
    print(f"  {label}  —  {total} examples")
    print(f"{'='*width}")

    print(f"\n  Referral:")
    print(f"    true  : {referral_cnt[True]:4d}  ({referral_cnt[True]/total*100:.1f}%)")
    print(f"    false : {referral_cnt[False]:4d}  ({referral_cnt[False]/total*100:.1f}%)")

    print(f"\n  Severity:")
    for sev in ["mild", "moderate", "severe"]:
        c = severity_cnt[sev]
        bar = "█" * int(c / total * 30)
        print(f"    {sev:10s}: {c:4d}  ({c/total*100:.1f}%)  {bar}")

    print(f"\n  Age group:")
    for ag in ["child", "adult", "elderly"]:
        c = age_group_cnt[ag]
        print(f"    {ag:10s}: {c:4d}  ({c/total*100:.1f}%)")

    print(f"\n  Gender:")
    for g in ["M", "F", "unknown"]:
        c = gender_cnt[g]
        print(f"    {g:10s}: {c:4d}  ({c/total*100:.1f}%)")

    if duration_vals:
        avg = sum(duration_vals) / len(duration_vals)
        print(f"\n  Duration (non-null): {len(duration_vals)} examples, avg {avg:.1f} days")
        print(f"  Duration null: {total - len(duration_vals)} examples")

    avg_sym = sum(sym_per_ex) / len(sym_per_ex)
    print(f"\n  Symptoms per example: avg {avg_sym:.2f}")
    dist = Counter(sym_per_ex)
    for k in sorted(dist):
        print(f"    {k} symptom(s): {dist[k]}")

    print(f"\n  Canonical symptom coverage:")
    min_count = min(symptom_cnt.get(s, 0) for s in CANONICAL_SYMPTOMS)
    for sym in CANONICAL_SYMPTOMS:
        c = symptom_cnt.get(sym, 0)
        flag = " ← LOW" if c < 10 else ""
        print(f"    {sym:20s}: {c:4d}{flag}")
    print(f"  Min coverage: {min_count} (need >= 10)")

    print(f"\n  Language category breakdown:")
    for cat, cnt in sorted(category_cnt.items(), key=lambda x: -x[1]):
        print(f"    {cat:28s}: {cnt:4d}")

    print()


def validate_jsonl(path: Path) -> tuple[int, int]:
    """Return (valid_count, invalid_count)."""
    valid = invalid = 0
    with path.open(encoding="utf-8") as fh:
        for i, line in enumerate(fh, 1):
            line = line.strip()
            if not line:
                continue
            try:
                ex = json.loads(line)
                msgs = ex["messages"]
                assert len(msgs) == 3
                assert msgs[0]["role"] == "system"
                assert msgs[1]["role"] == "user"
                assert msgs[2]["role"] == "assistant"
                out = json.loads(msgs[2]["content"])
                assert "symptoms" in out and isinstance(out["symptoms"], list)
                assert "referral" in out and isinstance(out["referral"], bool)
                assert out["severity"] in ("mild", "moderate", "severe")
                assert out["ageGroup"] in ("child", "adult", "elderly")
                valid += 1
            except Exception as e:
                print(f"  Line {i}: INVALID — {e}")
                invalid += 1
    return valid, invalid


def main() -> None:
    parser = argparse.ArgumentParser(description="Print dataset statistics")
    parser.add_argument("--train", default="jansetu_symptoms_train.jsonl")
    parser.add_argument("--eval",  default="jansetu_symptoms_eval.jsonl")
    args = parser.parse_args()

    here = Path(__file__).parent

    for label, fname in [("TRAIN", args.train), ("EVAL", args.eval)]:
        path = here / fname
        if not path.exists():
            print(f"\n{label}: {path} not found. Run generate_dataset.py first.")
            continue
        print(f"\nValidating {path.name} …")
        valid, invalid = validate_jsonl(path)
        print(f"  {valid} valid, {invalid} invalid lines")
        if valid > 0:
            examples = load_jsonl(path)
            print_stats(examples, f"{label} — {path.name}")


if __name__ == "__main__":
    main()
