# 3. The Software Layer (the Python framework)

Words in **bold** are explained in the [glossary](02_glossary.md).

## 3.1 What it is
A Python program for Windows that collects evidence and tells you what looks suspicious. It runs **offline** (no internet use).

## 3.2 The parts (folders in `src/`)

| Part | What it does, in plain words |
|------|------------------------------|
| `capture/` | Looks at **live memory**. Walks through the memory of running programs using Windows' own functions and flags suspicious blocks (for example RWX blocks, runnable private memory that does not belong to a normal file). No special driver needed. |
| `intake/` | Receives evidence (a memory image or disk image) and computes its **hash** so it is provably unchanged. |
| `memory/` | Analyses a saved memory image (can use **Volatility**) to list processes. |
| `disk/` | Reads disk traces: Windows Prefetch (what programs ran), registry, etc. |
| `correlation/` | Joins everything into a **timeline** and gives **risk scores**. |
| `response/` | Writes the final **report**: an HTML page and a JSON file. |
| `hardware/` | **New.** Imports FSU simulation results (see next guide file). |
| `main.py` | The command-line program you type into. |

## 3.3 How you use it
Start it from the project folder:
```
python src/main.py
```
Then type commands:

| Command | What it does |
|---------|--------------|
| `/scan` | Quick read-only look at live memory; shows a table and saves a JSON file |
| `/capture` | Deeper capture: scan plus saving dumps of suspicious processes |
| `/analyze <type> <path> [mount]` | Analyse an existing image. Type is memory, disk or hybrid |
| `/fsu <folder> [scan.json]` | **New.** Import FSU simulation results and make a report; optionally merge a saved `/scan` result so both layers share one timeline |
| `/help`, `/exit`, `/clear` | Help, quit, clear screen |

## 3.4 How it solves the problem
1. **Collect**: memory + disk evidence, hashed.
2. **Detect**: rules flag suspicious items (a known hacking tool running, a program in a Temp folder, an RWX memory block).
3. **Correlate**: put all events on one time-ordered list so you see the story.
4. **Score**: 0-100 risk per item.
5. **Report**: one HTML page + JSON to hand to a reviewer.

## 3.5 Its weak point (why the hardware layer exists)
Everything above asks **Windows** for information. A **rootkit** that controls Windows can answer falsely, for example hide a process (**DKOM**). The scanner then reports "clean" while the attack is running.

The software layer is still very useful: most malware is not a rootkit, and it works on real computers today. The hardware layer is the research extension for the hardest case. See [04_hardware_layer_fsu.md](04_hardware_layer_fsu.md).
