# 6. How to run it, and how to demo it

## 6.1 What you need
- Windows computer with Python 3.12 (software layer).
- WSL2 with Ubuntu (for gem5). At least 8 GB RAM for WSL (we set 11 GB + 16 GB swap).
- First-time gem5 build takes 40 min to 3 hours. Do this **before** the demo.

## 6.2 One-time setup (already done on the author's computer)
In WSL (scripts in `hardware/fsu/scripts/`):
1. `setup_wsl.sh deps` (as root) installs build tools; `setup_wsl.sh` clones gem5 into `~/gem5`.
2. Apply the FSU patch: `cd ~/gem5 && git apply <repo>/hardware/fsu/gem5_patches/0001-fsu-memctrl.patch`
3. `build.sh` builds gem5.

## 6.3 Run the attack test
```
bash ~/hybrid-forensics-framework/hardware/fsu/scripts/run_fsu.sh
```
Look for:
- `Exiting @ tick ... because FSU: W^X violation`
- no `[FAILURE]` line,
- `1` alert counted and a file `0xc8000.bin` listed.

Other scripts:
- `run_variants.sh`: benign run, and attack with caches (with and without `clflush`).
- `run_overhead.sh`: speed comparison (needs the second, unmodified gem5 build).
- `hash_evidence.py`: fingerprints the saved page.

## 6.4 Show it in the Python framework
1. Copy the result folder (`fsu_trace.txt`, `stats.txt`, `fsu_evidence/`) to Windows.
2. `python src/main.py`
3. Type `/fsu <that folder>`
4. Open the HTML report; show the **Hardware layer (FSU)** section and the 100-score alert.

## 6.5 Five-minute demo script
| Min | Say / show |
|-----|-----------|
| 0-1 | The problem: fileless malware + rootkits blind software scanners. (Use the picture in [01_big_picture.md](01_big_picture.md)) |
| 1-2 | The idea: a watcher in the memory controller; write-then-execute is the red flag |
| 2-3 | Live: run `run_fsu.sh`; show "W^X violation", no `[FAILURE]` |
| 3-4 | Evidence: show the saved page starting `90 90 c3` and its SHA-256; run `/fsu` and open the report |
| 4-5 | Honesty slide: caches can hide it; CR3 is a placeholder; simulation only; measured overhead table |

## 6.6 If something goes wrong in the demo
- gem5 not built / WSL slow: show the saved results in `hardware/fsu/results/` and the screenshot of the report instead.
- Say what is real: the trace and numbers in `results/` are real saved outputs of real runs.
