#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(realpath -e "$(dirname "$0")")"

cd "$dir"

env \
    CIBW_PLATFORM='linux' \
    CIBW_ARCHS='x86_64' \
    CIBW_BUILD='cp3*-manylinux*' \
    CIBW_PROJECT_REQUIRES_PYTHON='>=3.10' \
    CIBW_MANYLINUX_X86_64_IMAGE='manylinux_2_28' \
    CIBW_BEFORE_ALL='./install-build-tools.sh && ./build-llvm.sh' \
    CIBW_TEST_COMMAND='{package}/test-installed.sh' \
    cibuildwheel \
    .

#    CIBW_DEBUG_KEEP_CONTAINER=1 \
#    CIBW_BUILD_VERBOSITY=1 \
