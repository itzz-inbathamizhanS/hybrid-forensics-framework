#!/usr/bin/env bash
# Runs benign and trigger variants in gem5 SE mode; saves trace/stdout/stats per case in results/variants/.
set -uo pipefail
REPO="${REPO:-$HOME/hybrid-forensics-framework}"
W="$REPO/hardware/fsu/workloads"; R="$REPO/hardware/fsu/results/variants"
mkdir -p "$R"
gcc -O0 -static "$W/benign.c" -o "$W/benign"
gcc -O0 -static "$W/fsu_trigger.c" -o "$W/fsu_trigger"
gcc -O0 -static -DUSE_CLFLUSH "$W/fsu_trigger.c" -o "$W/fsu_trigger_clflush"
cd "$HOME/gem5"
run() {  # name binary flags...
    local name=$1 bin=$2; shift 2
    rm -rf m5out
    timeout 1800 ./build/X86/gem5.opt --debug-flags=FSU --debug-file=fsu_trace.txt \
        configs/deprecated/example/se.py --cpu-type=TimingSimpleCPU "$@" --cmd="$W/$bin" \
        > "$R/$name.stdout.txt" 2>&1
    local rc=$?
    cp m5out/fsu_trace.txt "$R/$name.trace.txt" 2>/dev/null || : > "$R/$name.trace.txt"
    grep -E 'simTicks|simInsts|system.cpu.ipc' m5out/stats.txt > "$R/$name.stats.txt" 2>/dev/null
    echo "$name rc=$rc alerts=$(grep -c FSU-ALERT "$R/$name.trace.txt") failure_line=$(grep -c FAILURE "$R/$name.stdout.txt") evidence=$(ls m5out/fsu_evidence 2>/dev/null | wc -l)"
}
run benign_nocache benign
run trigger_cache fsu_trigger --caches --l2cache
run trigger_cache_clflush fsu_trigger_clflush --caches --l2cache
