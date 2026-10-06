# 8. Review checklist and likely questions

## 8.1 Checklist for reviewers
- [ ] Read [01_big_picture.md](01_big_picture.md) and can explain the problem in your own words.
- [ ] Understand "write then execute" (W^X) and why it is a red flag.
- [ ] Know the two layers and why the second exists (rootkit can lie to software).
- [ ] Check the saved evidence: `hardware/fsu/results/fsu_trace.txt` and `evidence_hashes.json`.
- [ ] Check the numbers in [07_results_and_honest_limits.md](07_results_and_honest_limits.md) against `docs/fsu/results.md` and the raw files in `hardware/fsu/results/`.
- [ ] Run the tests: `python -m pytest tests -q` (install `requirements.txt` first).
- [ ] Look for any claim that is not backed by a saved result. Report it.
- [ ] Check no claim says "prove" for hardware performance.

## 8.2 Likely questions and honest answers

**Q: Is the FSU real hardware?**
No. It is a simulation in gem5. It shows the idea is feasible for one test attack.

**Q: Why gem5 instead of building it?**
Building a chip is impossible for this project and cannot be changed afterwards. gem5 lets us test the idea in code. See [05_why_gem5.md](05_why_gem5.md).

**Q: Why not just improve the Python scanner?**
Python runs on the OS. A rootkit that controls the OS can lie to it. The FSU watches below the OS.

**Q: Does it really stop the malware?**
In the simulation the request is never answered, so the program stays blocked and the simulation ends. A real controller cannot literally halt a core; real hardware would need a different mechanism (for example a signal to the CPU). We call it an abstract stall.

**Q: What if the attack is hidden in the cache?**
Then the FSU at the memory controller can miss it. We measured this: it missed the attack unless the code flushed the cache line. This is the biggest limitation.

**Q: What about false alarms?**
One harmless program gave none. But programs that legitimately write then run code (JIT: browsers, Java) would be flagged. We did not measure this.

**Q: What is the performance cost?**
In our setup (no caches, one program), assuming a 1 ns lookup delay: 2.35 % longer. 5 ns: 10.31 %. These depend on the assumed delay, which is not a real hardware measurement.

**Q: Where did "<1% overhead" in the original draft come from?**
It was not backed by a measurement and we removed it.

**Q: What is "CR3" and why do you only log it?**
CR3 helps hardware translate virtual to physical addresses to find which program owns a page. In SE mode there is no real OS, so the value is not meaningful. We log it as a placeholder and say so.

**Q: How is the evidence trustworthy?**
The page is saved at the moment of the alert and fingerprinted with SHA-256. We checked the fingerprint with two independent tools and they matched.

**Q: What is new compared to the original Python project?**
The hardware layer (FSU in gem5), the importer and `/fsu` command, a new scoring rule, a new report section, tests, and this documentation.

**Q: How do the two layers share one timeline?**
`/fsu <folder> [scan.json]` imports the FSU events (with simulated-time stamps) and can merge a saved software `/scan` result, then writes one report.

## 8.3 Where to give feedback
Write comments on the pull request, or note the file name and the line you disagree with.
