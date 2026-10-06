#!/usr/bin/env bash
# Builds gem5 X86 opt. -j = cores-1, capped at 6 to stay within WSL memory.
set -euo pipefail
cd "$HOME/gem5"
J=$(( $(nproc) - 1 )); [ "$J" -gt 6 ] && J=6
scons build/X86/gem5.opt -j"$J"
