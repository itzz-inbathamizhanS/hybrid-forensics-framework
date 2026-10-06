# FSU Technical Architecture

> Converted from `FSU_Technical_Architecture.docx` (friend's draft). Claims not backed by a measured run in `hardware/fsu/results/` are marked **TO VERIFY**. Do not quote them as results.

## 1. Overview
The Forensic Snoop Unit (FSU) moves detection of fileless memory-resident malware below the OS, into the memory controller (IMC). Goal: detect and extract compromised physical pages without relying on the host OS.

## 2. Why software forensics can be blinded
EDR and memory scanners run in Ring 3/0. A Ring 0 rootkit can use DKOM to unlink processes from OS lists, so a scanner querying the OS gets a "clean" memory map. Software layer limitation in this project: `src/capture/native_ram.py` trusts OS-reported regions.

## 3. Why hardware
- **Semantic gap:** raw physical dumps need OS page tables to map to virtual context.
- **Observer effect:** running a software acquisition tool alters memory/cache state. **TO VERIFY** magnitude.
- **IOMMU:** external PCIe/DMA acquisition can be blocked by a Ring 0 rootkit reconfiguring the IOMMU.

## 4. Design (hardware concept)
All memory requests pass the IMC, so a tap there sees them.
1. **Passive tap:** mirrors request metadata (op, physical address). "No delay to the critical path" is **TO VERIFY**; the simulation adds a configurable `fsu_lookup_latency`.
2. **Page-table walker:** reads CR3 and walks PML4. In gem5 SE mode only CR3 is logged (stand-in); a real walk needs FS mode. **TO VERIFY**
3. **W^X detection FSM:** tracks pages that were written; an instruction fetch from such a page is flagged. Limit: the written-page set only grows, so JIT/loader code is a false positive.
4. **Stall-and-evacuate:** halts the CPU thread and copies the page out. A memory controller cannot suspend a core in real silicon; the simulation uses `tc->suspend()` as an abstract stall. "Non-maskable", "mid-cycle freeze" and "before any further instruction retires" are **TO VERIFY** (modelling shortcut, not a guarantee).
5. **Secure storage + SHA-256:** isolated storage inaccessible to Ring 0 and an inline crypto engine. Not simulated. In this project the page is dumped to `m5out/fsu_evidence/` and hashed in Python.

## 5. Validation approach
Implemented in gem5 by patching `MemCtrl` (see `gem5_guide.md` and `hardware/fsu/gem5_patches/`).

The original draft claims "proves ... less than a 1% degradation in IPC". That is **TO VERIFY** and is **not** a result of this project. Overhead will be measured in Phase 6 and recorded in `docs/fsu/results.md`; claims here will then be rewritten to match.

## 6. Known limits
- Cached runs: the controller only sees cache misses/writebacks; a dirty line may never reach it. Cached variant needs `clflush` in the trigger. **TO VERIFY**
- SE mode: CR3 not meaningful.
- Zero-trust / "mathematically verifiable" wording is marketing, not demonstrated.
