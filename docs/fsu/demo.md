# Demo script (about 5 minutes)

**1. Problem.** Software scanners trust the OS; a Ring 0 rootkit (DKOM) can hide memory from them. The FSU taps the memory controller, below the OS.

**2. Live run (WSL).**
```
wsl -e bash ~/hybrid-forensics-framework/hardware/fsu/scripts/run_fsu.sh
```
Show: `Exiting @ tick ... because FSU: W^X violation`; no `[FAILURE]` line; `1` alert counted; `0xc8000.bin` listed.

**3. Evidence.** `hardware/fsu/results/fsu_trace.txt` (ALERT, CR3, EVAC, STALL lines); `evidence_hashes.json` (SHA-256 `d9d4e30a...`, first bytes `9090c3` = NOP NOP RET).

**4. Framework.** Copy the run folder (trace, stats, `fsu_evidence/`) to Windows, then in `python src/main.py`: `/fsu <folder>`. Open the HTML report and show the "Hardware layer (FSU)" section and the 100-score threat.

**5. Honest limits.**
- With caches, the attack is missed unless the code flushes (`clflush`); see `docs/fsu/results.md`.
- CR3 is a placeholder in SE mode; no page-table walk.
- Written-page set only grows, so JIT/loaders would false-positive.
- The stall is abstract: a memory controller cannot halt a core in real silicon.
- Overhead: see the measured table in `results.md` (Phase 6); no other number is claimed.
