#!/usr/bin/env bash
# Installs gem5 build deps and clones gem5 (stable) into ~/gem5. Run inside WSL2 Ubuntu.
# apt step needs root: run `sudo bash setup_wsl.sh deps` (or `wsl -u root`), then `bash setup_wsl.sh` as your user.
set -euo pipefail
if [ "${1:-}" = "deps" ]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y build-essential git m4 scons zlib1g zlib1g-dev \
        libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
        python3-dev python3-venv python3-pip libboost-all-dev pkg-config
    exit 0
fi
[ -d "$HOME/gem5/.git" ] || git clone https://github.com/gem5/gem5.git "$HOME/gem5"
cd "$HOME/gem5"
git checkout stable
git log -1 --oneline
