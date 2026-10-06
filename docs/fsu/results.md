# FSU results (measured gem5 runs only)

gem5 `stable` f5c5a6e390, X86, SE mode, TimingSimpleCPU. Raw traces/stats: `hardware/fsu/results/` (variants in `results/variants/`). Patch: `hardware/fsu/gem5_patches/0001-fsu-memctrl.patch`.

## Phase 2/3 detection runs (one run each)

| Case | Caches | FSU alerts | `[FAILURE]` printed | Evidence page | simInsts |
|---|---|---|---|---|---|
| trigger | none | 1 (page 0xc8000) | no | yes, starts `90 90 c3` | 140131 |
| benign | none | 0 | n/a | none | 4,562,621 |
| trigger | L1+L2 | **0 (missed)** | **yes** | none | 141,943 |
| trigger + clflush | L1+L2 | 1 (page 0xc8000) | no | yes | 140,138 |

## Findings
- **Detection works in the no-cache model.** The fetch from the freshly written page was caught and the request held.
- **No false positive on the single benign workload** (compute plus writes to its own buffers). One program only; this does not show an absence of false positives in general (JIT/loaders would be flagged, see limits).
- **Cached runs without a flush miss the attack.** With caches the written line stayed in the cache hierarchy and the controller never saw the fetch/write pair, so the payload ran to completion. A snoop at the memory controller alone is blind to this unless the line reaches DRAM; `clflush` forces that and the FSU then catches it. Real malware need not flush, so this is a real limit of the memory-controller placement.

## Implementation notes / deviations
- No new `system` param: `qos::MemCtrl` already provides `system()`.
- `tc->suspend()` was dropped. In the cached clflush run it crashed gem5 (`TimingSimpleCPU::suspendContext` assertion: CPU was waiting on a response). The stall is now abstract: the request is never answered, so the CPU stays blocked, then `exitSimLoop` ends the run.
- CR3 is logged (`0x64`) but is a placeholder in SE mode; no page-table walk is done.
- Written-page set only grows (JIT/loader false positives).

## Not yet measured
IPC/runtime overhead of the FSU (Phase 6). The raw IPC values in `results/variants/*.stats.txt` come from different workloads and must not be compared as overhead.
