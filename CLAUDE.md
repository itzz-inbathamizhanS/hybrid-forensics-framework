# CLAUDE.md — Hybrid Forensics Framework + Forensic Snoop Unit (FSU)

Read this first, then HANDOFF.md. Do not read anything else until the current task needs it.

## What this project is
Two layers aimed at one goal: catching fileless malware (reflective injection, shellcode) in memory.

1. **Software layer (existing, Python, Windows).** `src/` holds a live-RAM scanner (Win32 via ctypes) that flags RWX / suspicious private executable regions. It also has disk artifact parsing, a correlation timeline, threat scoring and HTML/JSON reports.
2. **Hardware layer (new, gem5 simulation).** The FSU is modelled inside gem5's memory controller (`MemCtrl`). It:
   - tracks physical pages that have been written;
   - flags an instruction fetch from such a page (a W^X violation);
   - halts the simulated CPU;
   - dumps the page and computes its SHA-256 as forensic evidence.

**Story to preserve.** Software scanners can be blinded by kernel rootkits (DKOM, IOMMU tampering). The FSU sits below the OS, so it can't be. The Python framework imports the FSU results and shows both layers on one timeline.

## Hard rules
- Git author is always `Inbathamizhan S`. Check with `git config user.name` before any commit.
- **Stop before writing code.** At the start of a phase, explain the plan and the files you'll touch, then wait for the user to say "go". The user may switch models between planning and coding.
- At the end of every session, update the **Status** and **Next step** sections of `HANDOFF.md`. The next model has no memory of this session.
- Be honest in results. No claim (overhead %, "proves", "zero instructions") goes into docs unless it comes from a measured run in `hardware/fsu/results/`.
- Keep the air-gapped principle for `src/`: no network calls.

## Saving tokens (important — the user is on a limited plan)
- Never open `venv/`, `__pycache__/`, `.git/`, `winpmem.exe`, `*.raw`, or the gem5 source tree, except for the specific gem5 file being patched.
- Use `grep -n` or a line range instead of reading whole files. `src/capture/native_ram.py` is 651 lines, so read only the function you need.
- Work on one phase per session. Don't re-explain the background, and don't print whole files back to the user.
- Prefer small diffs and patches over rewriting files.

## Environment
- Windows. The repo is cloned at `D:\hybrid-forensics-framework`. Python 3.12, with venv at `venv\` (local only, not committed).
- gem5 runs in **WSL2 Ubuntu 22.04/24.04**. gem5 lives at `~/gem5` in the WSL filesystem, not `/mnt/d`, because building under `/mnt/d` is very slow. The repo is reachable from WSL at `/mnt/d/hybrid-forensics-framework`.
- Building gem5 needs at least 8 GB RAM, and the first `scons build/X86/gem5.opt` takes 1–3 h. Use `-j` equal to the number of cores minus 1.

## Layout (target)
```
src/                    existing Python framework (entry: src/main.py)
src/hardware/           NEW: fsu_importer.py, which parses gem5 FSU trace + stats + evidence into CorrelatedEvents
hardware/fsu/
  gem5_patches/         0001-fsu-memctrl.patch (git diff from gem5 stable; gem5 itself is NOT in this repo)
  workloads/            fsu_trigger.c, benign.c
  scripts/              setup_wsl.sh, build.sh, run_fsu.sh, run_baseline.sh
  results/              trace logs, stats.txt copies, evidence/ (large files gitignored)
docs/fsu/               architecture.md, gem5_guide.md, results.md
```

## gem5 FSU design decisions (already agreed)
- Debug flag `FSU` is registered in `src/mem/SConscript`.
- `MemCtrl` gets a param `system = Param.System(Parent.any, ...)` in `src/mem/MemCtrl.py`, which gives it access to threads and physical memory.
- The tap sits at the top of `MemCtrl::recvTimingReq`. Writes insert `page = addr & ~Addr(0xFFF)` into an `unordered_set`. An IFetch on a page in the set raises an alert.
- On alert:
  1. Log the alert.
  2. Read `Cr3` from the thread context and log it (a stand-in for the page-table walker).
  3. Do a functional read of the 4 KB page and write it to `m5out/fsu_evidence/<paddr>.bin`.
  4. `tc->suspend()`, then `exitSimLoop("FSU: W^X violation")`.
- Check `req->hasContextId()` before calling `contextId()`.
- Add param `fsu_lookup_latency` (default 0) so the overhead can be measured honestly.
- First runs use **no `--caches`**. The cached variant comes later and uses `clflush` in the trigger to force the write to DRAM.
- Known limits to document, not hide:
  - the written-page set only grows, so JIT code would be a false positive;
  - in SE mode, CR3 is not meaningful (FS mode is needed for a real walk);
  - a memory controller can't suspend a core in real silicon, so treat the suspend as an abstract stall line.

## Run commands (WSL)
```
cd ~/gem5 && scons build/X86/gem5.opt -j$(($(nproc)-1))
./build/X86/gem5.opt --debug-flags=FSU --debug-file=fsu_trace.txt \
  configs/deprecated/example/se.py --cpu-type=TimingSimpleCPU \
  --cmd=/mnt/d/hybrid-forensics-framework/hardware/fsu/workloads/fsu_trigger
```
Success means `[FSU-ALERT]` appears in `m5out/fsu_trace.txt`, the `[FAILURE]` line never prints, and `fsu_evidence/*.bin` exists.
