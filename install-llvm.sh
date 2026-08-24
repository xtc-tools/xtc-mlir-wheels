#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

INDEX_URL=https://pypi.org/simple
LLVM_VERSION=22.1.8.2

python3 -m pip install \
        "xtc-llvm-tools==$LLVM_VERSION" \
        "xtc-llvm-dev==$LLVM_VERSION" \
        --index-url "$INDEX_URL"
