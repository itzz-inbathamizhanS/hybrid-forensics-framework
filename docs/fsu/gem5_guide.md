# FSU in gem5: Implementation Guide

> Converted from `FSU_gem5_Implementation_Guide.docx` and corrected to the agreed design in `CLAUDE.md`. Code snippets are a starting point, **TO VERIFY** against the checked-out gem5 tree (API drift). gem5 lives in WSL at `~/gem5`, not in this repo.

## 1. Setup (WSL2 Ubuntu 22.04/24.04)
```
sudo apt update
sudo apt install -y build-essential git m4 scons zlib1g zlib1g-dev \
    libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    python3-dev python3-six python3-venv libboost-all-dev pkg-config
git clone https://github.com/gem5/gem5.git ~/gem5
cd ~/gem5 && git checkout stable
```

## 2. Modifications
- `src/mem/SConscript`: `DebugFlag('FSU', 'Microarchitectural traces for Forensic Snoop Unit')`
- `src/mem/MemCtrl.py`: add `system = Param.System(Parent.any, ...)` and `fsu_lookup_latency` (default 0).
- `src/mem/mem_ctrl.hh`: `std::unordered_set<Addr> fsu_writable_pages;` plus `fsuInspectPacket`, `fsuAssertStall`, `fsuEvacuatePayload` (needs `<unordered_set>`).
- `src/mem/mem_ctrl.cc`: include `debug/FSU.hh`, `cpu/thread_context.hh`.
  - Tap at top of `MemCtrl::recvTimingReq`.
  - Write: insert `addr & ~Addr(0xFFF)`. IFetch on a page in the set: alert.
  - On alert: log `[FSU-ALERT]`, read/log CR3, functional-read the 4 KB page to `m5out/fsu_evidence/<paddr>.bin`, `tc->suspend()`, `exitSimLoop("FSU: W^X violation")`.
  - Check `req->hasContextId()` before `contextId()`.

Corrections versus the original draft: the draft's evacuation was a log-only stub; its sample output used a virtual-looking address (`0x7ffff7ffb000`) although the controller sees physical addresses; returning `true` without a response leaves the request pending (modelling shortcut, not an exact "zero instructions retired" guarantee).

## 3. Workload
`hardware/fsu/workloads/fsu_trigger.c`: `mmap` RWX page, write `{0x90,0x90,0xC3}` (NOP, NOP, RET), call it; print `[FAILURE]` if it returns. Build: `gcc -O0 -static fsu_trigger.c -o fsu_trigger`. Optional `clflush` variant behind `#ifdef`.

## 4. Build and run
```
cd ~/gem5 && scons build/X86/gem5.opt -j$(($(nproc)-1))
./build/X86/gem5.opt --debug-flags=FSU --debug-file=fsu_trace.txt \
  configs/deprecated/example/se.py --cpu-type=TimingSimpleCPU \
  --cmd=/mnt/d/hybrid-forensics-framework/hardware/fsu/workloads/fsu_trigger
```
First runs use no `--caches` (the draft used `--caches`; see limits).

## 5. Success criteria
`[FSU-ALERT]` in `m5out/fsu_trace.txt`, no `[FAILURE]` line, `fsu_evidence/*.bin` exists. Exact ticks and addresses will differ from any sample. Metrics: `grep -E "simTicks|simInsts|ipc" m5out/stats.txt`.

## 6. Known limits (document, don't hide)
- Cache path: with `--caches` the tap may never see the write/fetch. **TO VERIFY** per variant.
- Written-page set only grows: false positives on JIT/loaders.
- SE mode: CR3 not meaningful; FS mode needed for a real walk.
- Memory controller can't suspend a core in real silicon; abstract stall.
- `system()`, `contextId()`, `suspend()` differ across gem5 versions.
