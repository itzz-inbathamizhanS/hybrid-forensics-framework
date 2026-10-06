# Project Guide: Hybrid Forensics Framework + Forensic Snoop Unit (FSU)

This guide explains the whole project **from zero**. You do not need a technical background. Every technical word is explained in plain language, and there is a [glossary](02_glossary.md) for quick lookup.

> Note on names: the hardware idea is called the **FSU** (Forensic Snoop Unit). If you see "GSU" anywhere, it means the same thing (a typo for FSU).

## Read in this order

| # | File | What you learn | Time |
|---|------|----------------|------|
| 1 | [01_big_picture.md](01_big_picture.md) | The problem, the idea, the two layers. Start here. | 10 min |
| 2 | [02_glossary.md](02_glossary.md) | Every technical word in plain language | lookup |
| 3 | [03_software_layer.md](03_software_layer.md) | The existing Python tool: what it does and how to use it | 10 min |
| 4 | [04_hardware_layer_fsu.md](04_hardware_layer_fsu.md) | The FSU: what it is, how it catches an attack, step by step | 15 min |
| 5 | [05_why_gem5.md](05_why_gem5.md) | Why we use gem5 (a simulator) for the FSU and what that does and does not prove | 5 min |
| 6 | [06_how_to_run_and_demo.md](06_how_to_run_and_demo.md) | Exact steps to run it and a 5-minute demo script | 10 min |
| 7 | [07_results_and_honest_limits.md](07_results_and_honest_limits.md) | What we measured, and what we can NOT claim | 10 min |
| 8 | [08_review_checklist_and_faq.md](08_review_checklist_and_faq.md) | Checklist for reviewers and answers to likely questions | 10 min |

## The whole project in 5 sentences

1. Some modern malware never writes a file to disk. It hides only inside the computer's memory (RAM), so normal antivirus that checks files misses it.
2. Our **software layer** (Python) scans the computer's memory and disk, finds suspicious things, and builds one timeline and report.
3. But software can be fooled if the malware is powerful enough to lie to the operating system.
4. So we designed a **hardware layer (the FSU)**: a watcher placed at the memory itself, below the operating system, that notices the classic trick of "write code into memory, then run it" and freezes the computer to save evidence.
5. We could not build real chips, so we **simulated** the FSU in a tool called gem5, measured what we could honestly measure, and wrote down the limits.

## Where things are in the repository

| Folder | Contents |
|--------|----------|
| `src/` | The Python framework (software layer) and `src/hardware/` (FSU result importer) |
| `hardware/fsu/` | The FSU for gem5: patch, test programs, scripts, measured results |
| `docs/fsu/` | Technical write-ups (architecture, gem5 guide, results, demo) |
| `docs/guide/` | **This beginner guide** |
| `tests/` | Automatic tests |

Everything in this guide that is a number comes from a real run saved in `hardware/fsu/results/`. If a number is not there, we do not claim it.
