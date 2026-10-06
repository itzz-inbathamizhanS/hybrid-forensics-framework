# HANDOFF.md — read after CLAUDE.md

## Status
- Repo analysed. CLAUDE.md, HANDOFF.md and PROJECT_SETTINGS.md have been created.
- **No code written yet.** Nothing has been committed yet.
- The friend's source docs are in project knowledge: `FSU_Technical_Architecture.docx` and `FSU_gem5_Implementation_Guide.docx`. Their known flaws are listed in CLAUDE.md under "design decisions" and "known limits".

## Next step
Phase 0. The user runs the setup commands in `PROJECT_SETTINGS.md` §3, then asks the model to do Phase 0.

---

## Phases (one per session; stop and confirm the plan before coding each one)

### Phase 0 — Repo hygiene (Python side, Windows)
- `git rm -r --cached venv src/**/__pycache__ winpmem.exe`. Keep the files on disk.
- Extend `.gitignore` with `*.exe`, `*.raw`, `hardware/fsu/results/**/*.bin` and `m5out/`.
- README: fix the clone URL to `itzz-inbathamizhanS/hybrid-forensics-framework` and fix the entry point to `src/main.py`. Add a "Phase 2: Hardware FSU (gem5)" section with 3–4 lines.
- Create the empty folders `hardware/fsu/{gem5_patches,workloads,scripts,results}` and `docs/fsu/`, each with a `.gitkeep`.
- Convert the two friend docx files into `docs/fsu/architecture.md` and `docs/fsu/gem5_guide.md`. Mark unverified claims as **TO VERIFY**.
- Commit as Inbathamizhan S.

### Phase 1 — WSL2 + baseline gem5
- `hardware/fsu/scripts/setup_wsl.sh` installs the apt deps (see the guide §1), clones gem5 into `~/gem5` and checks out `stable`.
- `build.sh` runs scons for X86 `gem5.opt`.
- Smoke test: run the gem5 hello test (`tests/test-progs/hello/bin/x86/linux/hello`) with se.py. Save the output to `results/baseline_hello.txt`.

### Phase 2 — FSU core in gem5 (no caches)
- Patch `src/mem/SConscript` (flag), `MemCtrl.py` (params `system` and `fsu_lookup_latency`), `mem_ctrl.hh` and `mem_ctrl.cc`, following the design in CLAUDE.md.
- `workloads/fsu_trigger.c` uses the guide's code plus a `clflush` option behind `#ifdef`. Build it with `gcc -O0 -static`.
- `run_fsu.sh` runs the trigger with no caches. Pass criteria are in CLAUDE.md.
- Save the patch: `cd ~/gem5 && git diff > /mnt/d/.../gem5_patches/0001-fsu-memctrl.patch`.

### Phase 3 — False-positive and caches check
- `workloads/benign.c` does normal compute and writes without executing written memory. It must produce **no** alert.
- Run the trigger with `--caches` and `--l2cache`, once with clflush and once without. Record which variants the FSU sees.
- Write the findings to `docs/fsu/results.md`.

### Phase 4 — Evacuation + evidence
- Make sure the page dump in `m5out/fsu_evidence/` works and the CR3 value is logged.
- Compute SHA-256 on the Python side, reusing the hashing in `src/intake/validator.py`.

### Phase 5 — Python bridge
- `src/hardware/fsu_importer.py` parses `fsu_trace.txt` (the `[FSU-ALERT]`, `[FSU-STALL]` and `[FSU-EVAC]` lines with ticks), `stats.txt` (simTicks, simInsts, ipc) and the evidence files. It outputs a list of `CorrelatedEvent`.
- `schemas.py`: add `"hardware"` to the `source_module` Literal.
- `threat_scorer.py`: a hardware W^X alert gets the max score.
- `report_generator.py`: add a section titled "Hardware layer (FSU)".
- `main.py`: add a menu option "Import FSU simulation results (folder)".
- Add tests in `tests/` using a small fake trace file.

### Phase 6 — Measurement + honest docs
- Overhead: run `benign` on baseline gem5 and on the FSU build with `fsu_lookup_latency` set to 0, 1 and 5 cycles. Put a table of ipc and simTicks in `results.md`.
- Rewrite the claims in `docs/fsu/architecture.md` to match the measured numbers. Update the README and `docs/presentation.md`.
