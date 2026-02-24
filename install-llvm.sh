#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

INDEX_URL=https://pypi.org/simple
LLVM_VERSION=21.1.2.6

python3 -m pip install \
        "xtc-llvm-tools==$LLVM_VERSION" \
        "xtc-llvm-dev==$LLVM_VERSION" \
        --index-url "$INDEX_URL"
