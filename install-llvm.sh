#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

LLVM_VERSION=21.1.2.2025091603+b708aea0

python -m pip install \
        "llvm==$LLVM_VERSION" \
        --index-url https://gitlab.inria.fr/api/v4/projects/57611/packages/pypi/simple
