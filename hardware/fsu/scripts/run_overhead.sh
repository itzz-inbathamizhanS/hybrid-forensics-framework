#!/usr/bin/env bash
# Overhead measurement: benign workload, no caches, TimingSimpleCPU.
# Baseline = unpatched gem5 (~/gem5_base); FSU = patched (~/gem5) with fsu_lookup_latency 0ns,1ns,5ns.
# Repeats N times (default 3) and saves stats per run to results/overhead/.
set -uo pipefail
REPO="${REPO:-$HOME/hybrid-forensics-framework}"
W="$REPO/hardware/fsu/workloads/benign"; R="$REPO/hardware/fsu/results/overhead"
N="${N:-3}"; mkdir -p "$R"
run() {  # label gem5dir fsu_lat
    local label=$1 dir=$2 lat=$3
    for i in $(seq 1 "$N"); do
        local out; out=$(mktemp -d)
        ( cd "$dir" && FSU_LAT="$lat" GEM5_ROOT="$dir" ./build/X86/gem5.opt -d "$out" \
            "$REPO/hardware/fsu/scripts/se_fsu.py" --cpu-type=TimingSimpleCPU --cmd="$W" \
            > "$R/${label}_$i.stdout.txt" 2>&1 )
        grep -E 'simTicks|simInsts|system.cpu.ipc|hostSeconds' "$out/stats.txt" > "$R/${label}_$i.stats.txt"

        echo "$label run $i: $(grep -E 'simTicks' "$R/${label}_$i.stats.txt" | awk '{print $2}')"
        rm -rf "$out"
    done
}
run baseline "$HOME/gem5_base" ""
run fsu_0ns  "$HOME/gem5" "0ns"
run fsu_1ns  "$HOME/gem5" "1ns"
run fsu_5ns  "$HOME/gem5" "5ns"
