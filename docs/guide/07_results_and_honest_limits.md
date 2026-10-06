# 7. Results and honest limits

Every number below comes from a real run saved in `hardware/fsu/results/` (and `docs/fsu/results.md`). Setup: gem5 stable, X86, SE mode, TimingSimpleCPU.

## 7.1 Does it catch the attack? (one run each)

| Case | Caches | Alerts | Attack finished? | Evidence saved |
|------|--------|--------|------------------|----------------|
| Attack program | none | 1 | No, stopped | Yes (starts `90 90 c3`) |
| Harmless program | none | **0** | n/a | none |
| Attack program | L1 + L2 | **0 (missed)** | **Yes: attack ran** | none |
| Attack + `clflush` | L1 + L2 | 1 | No, stopped | Yes |

### What this tells us
- **Works** when memory traffic is visible (no caches).
- **No false alarm** on the one harmless program tested.
- **Important weakness:** with caches, the written code can stay inside the CPU cache, so the memory controller never sees the write or the fetch. The attack ran to the end unseen. Forcing the data out to RAM (`clflush`) makes the FSU see it again. Real malware does not have to flush, so a watcher **only at the memory controller can miss attacks** on a real cached CPU.

## 7.2 How much slower does the FSU make things?
Harmless program, no caches, 3 runs per row (all identical because gem5 is deterministic):

| Version | FSU lookup delay (assumed) | simTicks | IPC | Slower by |
|---------|---------------------------|----------|-----|-----------|
| Unmodified gem5 | none | 448,615,215,000 | 0.005085 | baseline |
| With FSU | 0 ns | 448,615,215,000 | 0.005085 | 0.00 % |
| With FSU | 1 ns | 459,159,249,000 | 0.004968 | 2.35 % |
| With FSU | 5 ns | 494,857,043,000 | 0.004610 | 10.31 % |

How to read it fairly:
- The 0 ns row is zero **by construction** (the model adds no time unless we tell it to).
- The 1 ns and 5 ns rows show the cost of a delay we **chose**, not a delay measured on real hardware.
- This is one program with no caches (very slow baseline, IPC about 0.005). A cached system could behave differently; we did not measure it.
- An early draft of the architecture document claimed "less than 1% IPC degradation". **We could not support that claim** and removed it: at 1 ns we measure 2.3%.

## 7.3 Things we can NOT claim
- That it works in real silicon.
- That a memory controller can freeze a CPU in real hardware (our stall is abstract: the request is simply never answered).
- That it detects attacks when caches hide them (we showed it can miss).
- That it has few false alarms in general (we tested one harmless program only). **JIT code** (browsers, Java) writes then runs code legitimately and would be flagged.
- That it resists rootkits in practice: we did not simulate a rootkit. This is the *motivation*, not a measured result.
- A real **CR3 page-table walk**: only the CR3 value is logged, and in SE mode it is not meaningful.

## 7.4 Other honest notes
- Our own bug found along the way: using the processor's "suspend" call crashed gem5 in the cached case, so we replaced it with the abstract stall and documented it.
- The tracked set of written pages only grows (never cleaned), a simple design choice that increases false alarms.

## 7.5 Good next steps (not done yet)
1. Full System mode with a real operating system and a real CR3 page-table walk.
2. More harmless programs (including JIT-like ones) to measure false alarms.
3. Measure overhead with caches.
4. Design a way for the FSU to see cached data (a placement closer to the CPU).
