#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

LLVM_VERSION=19.1.7.2025011201+cd708029

python -m pip install \
        "llvm==$LLVM_VERSION" \
        --index-url https://gitlab.inria.fr/api/v4/projects/57611/packages/pypi/simple
