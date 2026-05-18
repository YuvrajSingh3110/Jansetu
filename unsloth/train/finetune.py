#!/usr/bin/env python3
"""
Jansetu E4B Fine-tuning Script
===============================
Fine-tunes Gemma 4 E4B (or fallback Gemma 2 2B) using Unsloth + LoRA
on the Jansetu rural India health symptom dataset.

Usage:
    # Full training (300 steps, ~35-45 min on Colab T4):
    python finetune.py

    # Dry run — 5 steps only, verifies the pipeline works:
    python finetune.py --dry-run

    # Custom config file:
    python finetune.py --config path/to/config.yaml
"""

import argparse
import json
import sys
import time
from pathlib import Path

import torch
import yaml


def load_config(config_path: Path) -> dict:
    """Load and return training configuration from a YAML file."""
    if not config_path.exists():
        print(f"ERROR: Config file not found: {config_path}")
        print("       Run from the train/ directory, or pass --config explicitly.")
        sys.exit(1)
    with config_path.open() as fh:
        return yaml.safe_load(fh)


def detect_compute_dtype() -> tuple[bool, bool]:
    """
    Detect whether bfloat16 or float16 is supported.
    Returns (bf16, fp16) — only one will be True.
    """
    if not torch.cuda.is_available():
        return False, False
    device_cap = torch.cuda.get_device_capability()
    # bfloat16 requires Ampere (8.x) or newer
    if device_cap[0] >= 8:
        return True, False
    return False, True


def load_model(cfg: dict) -> tuple:
    """
    Load Gemma model + tokenizer via Unsloth FastModel.
    Falls back to gemma-2-2b-it if the primary model is unavailable.
    """
    try:
        from unsloth import FastModel
    except ImportError:
        print("ERROR: Unsloth is not installed.")
        print("       Run: pip install 'unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git'")
        sys.exit(1)

    model_name: str = cfg["model"]["name"]
    fallback_name = "google/gemma-2-2b-it"

    for attempt, name in enumerate([model_name, fallback_name]):
        try:
            print(f"\nLoading model: {name}")
            if attempt == 1:
                print(f"  (primary model '{model_name}' unavailable — using fallback)")
                print(f"  Update config.yaml 'model.name' once Gemma 4 E4B is released.")
            model, tokenizer = FastModel.from_pretrained(
                model_name=name,
                max_seq_length=cfg["model"]["max_seq_length"],
                load_in_4bit=cfg["model"]["load_in_4bit"],
                dtype=cfg["model"].get("dtype"),
            )
            allocated_gb = torch.cuda.memory_allocated() / 1e9
            print(f"  Model loaded successfully.")
            print(f"  GPU memory used: {allocated_gb:.2f} GB")
            return model, tokenizer
        except OSError as e:
            if attempt == 0:
                print(f"  Model not found ({name}). Trying fallback …")
                print(f"  Tip: run 'huggingface-cli login' if you need gated model access.")
            else:
                print(f"ERROR: Could not load fallback model either: {e}")
                sys.exit(1)
        except RuntimeError as e:
            if "CUDA out of memory" in str(e):
                print("\nERROR: CUDA out of memory while loading model.")
                print("  Fix: reduce batch_size to 1 in config.yaml")
                print("       or set load_in_4bit: true (already recommended)")
                sys.exit(1)
            raise


def apply_lora(model, cfg: dict):
    """Apply LoRA adapters via Unsloth's get_peft_model."""
    from unsloth import FastModel  # noqa: F401 — needed for peft method
    lc = cfg["lora"]
    print(f"\nApplying LoRA  r={lc['r']}  alpha={lc['alpha']}  "
          f"dropout={lc['dropout']}")
    model = FastModel.get_peft_model(
        model,
        r=lc["r"],
        lora_alpha=lc["alpha"],
        lora_dropout=lc["dropout"],
        bias=lc["bias"],
        target_modules=lc["target_modules"],
        use_gradient_checkpointing="unsloth",
        random_state=cfg["training"]["seed"],
    )
    return model


def load_dataset(cfg: dict, config_dir: Path) -> tuple:
    """Load JSONL train and eval datasets using HuggingFace datasets."""
    from datasets import load_dataset as hf_load_dataset

    train_file = (config_dir / cfg["dataset"]["train_file"]).resolve()
    eval_file  = (config_dir / cfg["dataset"]["eval_file"]).resolve()

    if not train_file.exists():
        print(f"\nERROR: Training dataset not found: {train_file}")
        print("  Fix: run  python ../dataset/generate_dataset.py  first.")
        sys.exit(1)
    if not eval_file.exists():
        print(f"\nERROR: Eval dataset not found: {eval_file}")
        print("  Fix: run  python ../dataset/generate_dataset.py  first.")
        sys.exit(1)

    train_ds = hf_load_dataset("json", data_files=str(train_file), split="train")
    eval_ds  = hf_load_dataset("json", data_files=str(eval_file),  split="train")

    print(f"\nDataset loaded:")
    print(f"  Train: {len(train_ds)} examples   ({train_file.name})")
    print(f"  Eval : {len(eval_ds)}  examples   ({eval_file.name})")
    return train_ds, eval_ds


def format_dataset(train_ds, eval_ds, tokenizer, cfg: dict) -> tuple:
    """Apply chat template to convert message dicts to model input strings."""

    def apply_template(batch: dict) -> dict:
        texts = [
            tokenizer.apply_chat_template(
                msgs,
                tokenize=False,
                add_generation_prompt=False,
            )
            for msgs in batch["messages"]
        ]
        return {"text": texts}

    train_ds = train_ds.map(apply_template, batched=True)
    eval_ds  = eval_ds.map(apply_template,  batched=True)

    print(f"\nChat template applied.")
    print(f"  Sample (first 200 chars): {train_ds[0]['text'][:200]} …")
    return train_ds, eval_ds


def build_trainer(model, tokenizer, train_ds, eval_ds, cfg: dict, dry_run: bool):
    """Construct the SFTTrainer with train-on-responses-only masking."""
    from trl import SFTTrainer, SFTConfig
    from unsloth.chat_templates import train_on_responses_only

    tc = cfg["training"]
    bf16, fp16 = detect_compute_dtype()

    max_steps = 5 if dry_run else tc["max_steps"]
    if dry_run:
        print("\nDRY RUN mode: training for 5 steps only.")

    trainer_cfg = SFTConfig(
        dataset_text_field="text",
        per_device_train_batch_size=tc["batch_size"],
        gradient_accumulation_steps=tc["gradient_accumulation_steps"],
        warmup_steps=tc["warmup_steps"],
        max_steps=max_steps,
        learning_rate=tc["learning_rate"],
        fp16=fp16,
        bf16=bf16,
        logging_steps=tc["logging_steps"],
        eval_strategy="steps",
        eval_steps=tc["eval_steps"] if not dry_run else 5,
        save_steps=tc["save_steps"],
        output_dir=tc["output_dir"],
        seed=tc["seed"],
        report_to="none",
        max_seq_length=cfg["model"]["max_seq_length"],
    )

    trainer = SFTTrainer(
        model=model,
        tokenizer=tokenizer,
        train_dataset=train_ds,
        eval_dataset=eval_ds,
        args=trainer_cfg,
    )

    # Mask everything except the assistant's response in the loss
    trainer = train_on_responses_only(
        trainer,
        instruction_part="<start_of_turn>user\n",
        response_part="<start_of_turn>model\n",
    )
    print(f"  train_on_responses_only applied — loss computed on assistant turns only.")
    return trainer


def print_training_summary(trainer_output, cfg: dict, start_time: float) -> None:
    """Print a human-readable training summary."""
    elapsed = time.time() - start_time
    stats = trainer_output.metrics if hasattr(trainer_output, "metrics") else {}

    print("\n" + "="*56)
    print("  TRAINING COMPLETE")
    print("="*56)
    print(f"  Total time     : {elapsed/60:.1f} minutes")
    print(f"  Final train loss: {stats.get('train_loss', 'N/A'):.4f}"
          if isinstance(stats.get('train_loss'), float) else
          f"  Final train loss: {stats.get('train_loss', 'N/A')}")
    best_eval = stats.get("eval_loss", "N/A")
    print(f"  Best eval loss : {best_eval}")
    print(f"  Model saved to : {cfg['training']['output_dir']}")
    print("="*56)


def export_model(model, tokenizer, cfg: dict) -> None:
    """Save the fine-tuned model in merged 16-bit format for LiteRT conversion."""
    export_dir  = cfg["export"]["output_dir"]
    save_method = cfg["export"]["save_method"]

    print(f"\nExporting model → {export_dir}  (method: {save_method})")
    model.save_pretrained_merged(export_dir, tokenizer, save_method=save_method)
    print(f"  Export complete. Hand this folder to the Android team.")
    print(f"  They run the standard LiteRT-LM conversion on it — same process as base model.")

    if cfg["export"].get("push_to_hub") and cfg["export"].get("hub_model_id"):
        hub_id = cfg["export"]["hub_model_id"]
        print(f"\nPushing to HuggingFace Hub: {hub_id}")
        model.push_to_hub_merged(hub_id, tokenizer, save_method=save_method)
        print(f"  Pushed successfully.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Jansetu E4B fine-tuning")
    parser.add_argument(
        "--config", default="config.yaml",
        help="Path to config.yaml (default: config.yaml in the same directory)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Run 5 training steps only — validates the full pipeline without committing to training"
    )
    args = parser.parse_args()

    config_path = Path(args.config)
    if not config_path.is_absolute():
        config_path = Path(__file__).parent / config_path

    print("="*56)
    print("  JANSETU E4B FINE-TUNING PIPELINE")
    print("="*56)
    print(f"  Config  : {config_path}")
    print(f"  Dry run : {args.dry_run}")
    print(f"  GPU     : {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU (no GPU)'}")

    if not torch.cuda.is_available():
        print("\nWARNING: No GPU detected. Training on CPU will be extremely slow.")
        print("         Use Google Colab with a T4 GPU for practical training.")

    cfg = load_config(config_path)

    try:
        model, tokenizer = load_model(cfg)
    except RuntimeError as e:
        if "CUDA out of memory" in str(e):
            print("\nERROR: CUDA out of memory during model load.")
            print("  Fix: set batch_size: 1 in config.yaml")
            sys.exit(1)
        raise

    model = apply_lora(model, cfg)

    config_dir = config_path.parent
    train_ds, eval_ds = load_dataset(cfg, config_dir)
    train_ds, eval_ds = format_dataset(train_ds, eval_ds, tokenizer, cfg)

    trainer = build_trainer(model, tokenizer, train_ds, eval_ds, cfg, args.dry_run)

    steps_per_min = 2.5  # rough estimate for T4
    est_min = cfg["training"]["max_steps"] / steps_per_min
    if not args.dry_run:
        print(f"\nStarting training — {cfg['training']['max_steps']} steps "
              f"(estimated {est_min:.0f}-{est_min*1.2:.0f} minutes on T4) …")

    start_time = time.time()
    try:
        result = trainer.train()
    except RuntimeError as e:
        if "CUDA out of memory" in str(e):
            print("\nERROR: CUDA out of memory during training.")
            print("  Fix: reduce batch_size to 1 in config.yaml")
            print("       or increase gradient_accumulation_steps to maintain effective batch size")
            sys.exit(1)
        raise

    print_training_summary(result, cfg, start_time)

    if not args.dry_run:
        export_model(model, tokenizer, cfg)
    else:
        print("\nDry run complete — all components validated successfully.")
        print("Remove --dry-run for full training.")


if __name__ == "__main__":
    main()
