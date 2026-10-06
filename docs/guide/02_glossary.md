# 2. Glossary: technical words in plain language

| Word | Plain meaning |
|------|---------------|
| **Digital forensics** | Studying a computer after an attack to find out what happened, like a detective at a crime scene. |
| **Evidence** | Any data that shows what happened (a file, a log line, a memory copy). |
| **Chain of custody / hash** | Proof that evidence was not changed. A **hash** is a fingerprint of data: change one bit and the fingerprint changes completely. |
| **SHA-256** | A popular, very strong kind of hash. 64 characters long, e.g. `d9d4e30a...`. Same data always gives the same SHA-256. |
| **RAM / memory** | The computer's short-term workspace. Fast. Cleared when power is off. |
| **Disk** | Long-term storage (files). Stays when power is off. |
| **Page** | RAM is cut into blocks of 4096 bytes (4 KB) called pages. The FSU tracks pages. |
| **Physical address** | The real position of a byte inside the RAM chips. The memory controller sees these. |
| **Virtual address** | The fake, per-program address a program uses; the system translates it to a physical one. |
| **Operating system (OS)** | Windows/Linux: the boss program that runs all other programs. |
| **Kernel / Ring 0** | The most powerful, trusted core of the OS. Programs in "Ring 3" (normal apps) are less powerful. |
| **Rootkit** | Malware that takes over the kernel so it can hide itself and lie to security tools. |
| **DKOM** | A rootkit trick: secretly edit the OS's own lists so a malicious program disappears from the "running programs" list. |
| **Fileless malware** | Malware that lives only in memory, never as a file on disk. |
| **Shellcode** | A small piece of machine code an attacker injects and runs. |
| **Reflective injection** | Loading and running code directly inside memory, without a file. |
| **Instruction fetch (IFetch)** | The processor reading the next instruction to run. "Running code" = a stream of instruction fetches. |
| **W^X (Write XOR Execute)** | Safety rule: a memory area should be writable OR runnable, not code that was just written and then run. Breaking it is the red flag. |
| **RWX** | A memory area that is Readable, Writable and eXecutable all at once: rare in normal programs, common in attacks. |
| **Memory controller** | The hardware that sits between the processor and the RAM chips. Every memory read/write goes through it. |
| **CPU / processor / core** | The chip part that runs instructions. |
| **Cache** | A tiny, very fast memory inside the CPU that keeps copies of recent data. Important: requests served from cache **never reach** the memory controller. |
| **clflush** | A processor instruction that pushes a cached line out to RAM. |
| **IPC** | Instructions Per Cycle: how many instructions the CPU finishes per clock tick. A speed measure; lower means slower. |
| **Tick / simTicks** | gem5's time unit. 1 tick = 1 picosecond (one millionth of a millionth of a second). simTicks = how much simulated time passed. |
| **Latency** | Delay. |
| **Overhead** | How much slower a system gets because of an added feature. |
| **CR3** | A CPU register that points to the tables the OS uses to translate virtual to physical addresses. A real FSU would use it to find which program owns a page. In our simulation it is only logged (placeholder). |
| **Page-table walker** | Hardware that follows those tables. Not implemented in our simulation. |
| **gem5** | A free, widely used research tool that simulates a computer (CPU, memory, etc.) in software. See [05_why_gem5.md](05_why_gem5.md). |
| **SE mode (Syscall Emulation)** | A gem5 mode that runs one program without booting a full operating system. Simple and fast. |
| **FS mode (Full System)** | A gem5 mode that boots a real OS inside the simulation. More realistic, harder. |
| **FSU (Forensic Snoop Unit)** | Our hardware watcher in the memory controller. ("GSU" in older notes = FSU.) |
| **W^X violation / alert** | The FSU's alarm: code was fetched from a page that had been written. |
| **Evidence page / evacuation** | The saved copy of the suspicious memory page. |
| **Stall / halt** | Freezing the processor. In our simulation this is abstract (see limits). |
| **False positive** | A false alarm: the FSU flags something harmless. |
| **False negative / miss** | A real attack that the FSU fails to see. |
| **JIT (just-in-time) code** | Legit programs (browsers, Java) that also write code to memory and run it. These can look like attacks, so they cause false positives. |
| **Timeline** | All events from all sources sorted by time, so you can read the story. |
| **Risk score** | Number 0-100 saying how suspicious an event is. FSU alerts get 100. |
| **MITRE ATT&CK / T1620** | A public catalogue of attacker techniques. T1620 = "Reflective Code Loading". |
| **Volatility** | A well-known memory-analysis tool the framework can use as a fallback. |
| **WSL2** | Windows Subsystem for Linux: lets Windows run Linux programs. Our gem5 runs here. |
| **Patch** | A saved set of code changes. Our gem5 changes are saved as `0001-fsu-memctrl.patch`. |
| **Air-gapped / offline** | No network use. The Python framework makes no network calls. |
| **Deterministic** | Same input always gives the exact same result. gem5 is deterministic, which is why repeated runs gave identical numbers. |
