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

## Phase 6: overhead of the FSU tap (measured)

Workload `benign.c`, SE mode, **no caches**, TimingSimpleCPU. Baseline = unpatched gem5 stable (`~/gem5_base`); FSU = patched build with `fsu_lookup_latency` set via `scripts/se_fsu.py`. The latency is added to every memory request that reaches the controller (`headerDelay`). Script: `scripts/run_overhead.sh`; raw stats: `results/overhead/`.

| Build | fsu_lookup_latency | simTicks | simInsts | IPC | simTicks vs baseline |
|---|---|---|---|---|---|
| baseline (unpatched) | n/a | 448,615,215,000 | 4,562,621 | 0.005085 | 0 |
| FSU | 0 ns | 448,615,215,000 | 4,562,621 | 0.005085 | +0.00% |
| FSU | 1 ns | 459,159,249,000 | 4,562,621 | 0.004968 | +2.35% |
| FSU | 5 ns | 494,857,043,000 | 4,562,621 | 0.004610 | +10.31% |

Reading these numbers honestly:
- Each configuration was run 3 times; the three runs were identical (gem5 is deterministic), so there is no variance estimate. Three runs are repeats, not independent samples.
- The FSU adds **no simulated time at 0 ns by construction**: the tap is modelled as a lookup with a configurable latency, not as simulated hardware. The 1 ns and 5 ns rows therefore show the cost of an *assumed* latency, not a measured hardware cost.
- Percentages are specific to this no-cache configuration, where every instruction goes to DRAM (IPC about 0.005), so they are not expected to carry over to a cached system. Cached overhead was not measured.
- Only one workload was measured.
- The "less than 1% IPC degradation" claim in the original draft is **not supported**: at 1 ns lookup latency the measured IPC drop is 2.3% in this setup. It would only hold for latencies well below 1 ns in this model, which was not tested.

## Not yet measured
Cached-system overhead, other workloads, real-silicon cost.
