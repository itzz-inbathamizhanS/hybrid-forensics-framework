#!/usr/bin/env bash
# Runs the FSU trigger in gem5 SE mode (no caches by default). Usage: run_fsu.sh [extra se.py flags]
# Output: ~/gem5/m5out/fsu_trace.txt and fsu_evidence/. Copies the trace to results/.
set -euo pipefail
REPO="${REPO:-$HOME/hybrid-forensics-framework}"
W="$REPO/hardware/fsu/workloads"
gcc -O0 -static "$W/fsu_trigger.c" -o "$W/fsu_trigger"
cd "$HOME/gem5"
rm -rf m5out/fsu_evidence
./build/X86/gem5.opt --debug-flags=FSU --debug-file=fsu_trace.txt \
  configs/deprecated/example/se.py --cpu-type=TimingSimpleCPU "$@" \
  --cmd="$W/fsu_trigger" | tee m5out/run_stdout.txt
echo "--- checks ---"
grep -c 'FSU-ALERT' m5out/fsu_trace.txt || true
grep -c 'FAILURE' m5out/run_stdout.txt || true
ls m5out/fsu_evidence 2>&1 || true
mkdir -p "$REPO/hardware/fsu/results"
cp m5out/fsu_trace.txt "$REPO/hardware/fsu/results/fsu_trace.txt"
grep -E 'simTicks|simInsts|system.cpu.ipc' m5out/stats.txt > "$REPO/hardware/fsu/results/fsu_stats.txt" || true
