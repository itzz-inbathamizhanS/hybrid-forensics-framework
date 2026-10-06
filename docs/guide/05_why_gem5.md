# 5. Why gem5? (and why a simulation)

## 5.1 The question
The FSU is a **hardware** idea: a new circuit inside a memory controller. Why are we using a software tool called **gem5** instead of building it?

## 5.2 Short answer
We cannot build a custom chip. It costs millions of dollars and years of work, and you cannot change a chip once it is made. gem5 lets us **build a virtual computer in software** and add the FSU to it in code, so we can test the idea cheaply and honestly before anyone spends money.

## 5.3 What gem5 is
- A free, open-source simulator used by universities and chip companies (for example in computer-architecture research papers).
- It models a processor, caches and memory controller in detail and counts time in **ticks**.
- It is **deterministic**: same program in = same numbers out. That makes experiments repeatable.
- We can read and edit its memory-controller source code. That is exactly where the FSU sits.

## 5.4 Why not other options?

| Option | Why not |
|--------|---------|
| Build a real chip | Impossible for a student project; cost and time |
| FPGA board (programmable chip) | Needs hardware and special skills; an FPGA on a PCIe card also sits *outside* the memory path and can be blocked by the OS through the IOMMU |
| Just write more Python | Python runs on the OS; it can be lied to. That is the original problem |
| A different simulator (QEMU) | QEMU is fast but does not model memory-controller timing or give cycle counts, so we could not measure any overhead |

## 5.5 What gem5 lets us do here
1. **Place the watcher** exactly in the memory controller.
2. **Run a test attack** and see if it is caught.
3. **Run a harmless program** and check there is no false alarm.
4. **Compare** an unmodified gem5 with the FSU version to measure slowdown (with an assumed delay for the FSU lookup).
5. **Test cache variations** and discover that caches can hide the attack.

## 5.6 What gem5 can NOT do
- It does **not prove** the FSU works in real silicon. It is a model of a computer, not a computer.
- The FSU's cost in a real chip (area, power, real delay) is unknown. We only measure the effect of an **assumed** delay.
- In SE mode there is no real operating system, so the realistic CR3 page-table walk is not done.

## 5.7 The right way to say it
> "In a gem5 simulation we **demonstrated** that a memory-controller watcher can detect the write-then-execute pattern, and we measured where it fails. This is a feasibility study, not a hardware proof."

Using the word "prove" for hardware performance would be wrong and reviewers will notice.

## 5.8 Our gem5 setup in one paragraph
gem5 version 25.1 (stable branch) runs inside **WSL2** (Linux on Windows). We use X86, **SE mode**, a simple one-instruction-at-a-time-with-timing CPU (`TimingSimpleCPU`). Our FSU is saved as a patch file `hardware/fsu/gem5_patches/0001-fsu-memctrl.patch` so anyone can apply it to gem5 and reproduce the results. A second, unmodified copy of gem5 was built as the baseline for comparison.
