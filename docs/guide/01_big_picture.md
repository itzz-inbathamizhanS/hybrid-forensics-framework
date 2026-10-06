# 1. The Big Picture (from zero)

## 1.1 What is "digital forensics"?
When a computer is attacked (for example a company computer gets a virus), investigators must find out **what happened, when, and how**. Collecting and studying the evidence left in a computer is called **digital forensics**. It is like a detective examining a crime scene, but the crime scene is a computer.

Two places hold evidence:
- **Disk** (hard drive / SSD): files, programs, logs, settings. Stays after shutdown.
- **Memory (RAM)**: what the computer is doing *right now*: running programs and their data. **Disappears when the power is off.**

## 1.2 The problem: malware that leaves no file
Old viruses were files. Antivirus finds the file and deletes it.

Newer attackers use **fileless malware**: the harmful code is never saved as a file. It is loaded straight into memory and run from there. No file means nothing for a disk scan to find. The only place to catch it is **memory, while it is running**.

A very common trick (called **reflective injection** / shellcode) works in two steps:
1. **Write**: the attacker puts harmful code into a block of memory (like writing a note).
2. **Execute**: the attacker then tells the computer to *run* that block (like following the note's instructions).

Normal programs do not do this. A normal program's instructions are loaded from a file that is marked "run only, do not modify". **Writing code into memory and then running it is a red flag.** This rule is called **W^X** ("Write XOR Execute"): memory should be either writable or runnable, not both after being written.

## 1.3 Our two-layer answer

### Layer 1: Software (Python, Windows), already existing
A Python program that, on a Windows computer:
- scans live memory for suspicious blocks (readable + writable + runnable, odd locations),
- reads disk traces (what programs ran, what was installed),
- joins everything into one **timeline**,
- gives each suspicious item a **risk score**,
- writes a **report** (HTML page and JSON file).

Details: [03_software_layer.md](03_software_layer.md).

### Layer 2: Hardware (FSU), new, simulated
**Why another layer?** Software runs *on top of* the operating system (Windows). Very powerful malware (a **rootkit**) can take control of the operating system itself and **lie** to the software scanner ("everything is fine here"). The scanner believes the lie.

The **Forensic Snoop Unit (FSU)** is a small watcher placed **inside the memory controller**, the hardware part that every memory read/write must pass through. Because it sits *below* the operating system, the operating system cannot lie to it or switch it off.

What the FSU does, in plain words:
1. **Watches** every memory request passing by.
2. **Remembers** which memory pages (4 KB blocks) have been *written to*.
3. **Alarms** if the processor later tries to *run code* from one of those pages (the write-then-execute trick).
4. **Freezes** the processor so the malware cannot continue or erase itself.
5. **Saves a copy** of that memory page as evidence and computes its **SHA-256** (a fingerprint that proves the evidence was not changed afterwards).

Details: [04_hardware_layer_fsu.md](04_hardware_layer_fsu.md).

### Joining the two layers
The Python framework can **import** the FSU results and show them **on the same timeline and in the same report** next to the software findings. One place to see both.

## 1.4 Honest status
- The software layer works on real Windows computers.
- The FSU exists **only as a simulation** (we cannot manufacture chips). The simulation shows the idea works for one test attack and shows where it fails. See [07_results_and_honest_limits.md](07_results_and_honest_limits.md).

## 1.5 One picture
```
   Attacker's code written into memory, then executed
                        |
        +---------------+----------------+
        |                                |
 SOFTWARE LAYER (on Windows)      HARDWARE LAYER (FSU, in memory controller)
 scans memory + disk              sees every memory request
 can be lied to by a rootkit      below the OS: cannot be lied to
        |                                |
        +---------------+----------------+
                        |
         Python framework: ONE timeline + ONE report
```
