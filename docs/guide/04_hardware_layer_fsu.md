# 4. The Hardware Layer: the Forensic Snoop Unit (FSU)

Words in **bold** are in the [glossary](02_glossary.md). ("GSU" in older notes means FSU.)

## 4.1 Where the FSU sits
A computer's memory path, simplified:

```
 CPU  ->  (cache)  ->  MEMORY CONTROLLER  ->  RAM chips
                            ^
                         FSU lives here
```
Every request that reaches RAM passes the **memory controller**. The OS (even a hijacked one) cannot change what the controller sees, so the FSU cannot be lied to by the OS.

## 4.2 What the FSU does (4 simple rules)
1. **Write seen** -> note the 4 KB **page** as "has been written".
2. **Instruction fetch seen** (CPU is running code from a page) -> check the note.
3. **Page was written before?** -> **W^X violation!** Raise the alarm.
4. On alarm: log it, record **CR3**, **save the page** as evidence, **stall** the CPU.

That is the "write code, then run it" trick of fileless malware, caught in the act.

## 4.3 The test attack we used
`hardware/fsu/workloads/fsu_trigger.c` is a tiny harmless program that behaves like reflective injection:
1. asks for a memory page that is readable, writable and runnable,
2. copies 3 bytes of code into it (`90 90 C3` = "do nothing, do nothing, return"),
3. jumps to run it,
4. prints `[FAILURE]` if it manages to finish (meaning the FSU did NOT stop it).

A matching **benign** program (`benign.c`) does normal calculations and writes to its own memory but never runs what it wrote. It must **not** raise an alarm.

## 4.4 What happened in our run (real, measured)
Without caches:
- The FSU raised **1 alert**, on page `0xc8000`.
- The `[FAILURE]` line **never printed**: the program was stopped.
- The saved page was 4096 bytes and starts with `90 90 c3`: exactly the injected code.
- Its SHA-256 is `d9d4e30ac33053e2b1d4cad5e8366d85f7325eda4cfd55574f4fd0e0fd590cdf`, verified by two independent tools (Python and `sha256sum`).
- The benign program raised **0 alerts**.

## 4.5 Components in the real-hardware idea vs what we built

| Idea (architecture document) | In our simulation |
|------------------------------|-------------------|
| Passive tap on memory requests | Yes: hook at the top of the memory controller's request handler |
| W^X detection state machine | Yes: a set of written pages + check on instruction fetch |
| Page-table walker using CR3 | **No.** CR3 is only logged (placeholder in SE mode) |
| Stall the CPU | **Abstract**: the request is never answered, so the CPU stays blocked. A memory controller cannot really halt a core in silicon |
| Evacuate the page + SHA-256 in hardware | Page dump to a file: **yes**. SHA-256 is computed afterwards in Python, not inside the simulator |
| Secure storage enclave | **No** |

## 4.6 How the FSU result reaches the Python framework
`src/hardware/fsu_importer.py` reads the simulation's output:
- `fsu_trace.txt` (the ALERT / CR3 / EVACUATION / STALL lines with times),
- `stats.txt` (instructions, simulated time, IPC),
- the saved page files (it hashes them),

and turns them into events on the same timeline. The alert gets risk score **100** and is labelled MITRE **T1620** (Reflective Code Loading). The HTML report gets a section titled **Hardware layer (FSU)**. Times from the simulator are shown as `SIM+0.011164413s` to make clear they are **simulated time, not clock time**.

## 4.7 Why it solves the original problem
- Rootkit hides the process from the OS -> scanner is blind.
- The FSU does not ask the OS; it watches the memory traffic itself -> the hiding trick does not apply.
- It stops the CPU and keeps a hashed copy -> the malware cannot erase itself and the evidence is trustworthy.

**But**: this is demonstrated in a simulation only, for one test attack, and has known weak spots (caches, false alarms from JIT code). Read [07_results_and_honest_limits.md](07_results_and_honest_limits.md).
