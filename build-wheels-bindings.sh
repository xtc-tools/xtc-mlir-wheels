#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(realpath -e "$(dirname "$0")")"

BUILD_LLVM_REVISION="$(cat "$dir"/llvm_revision.txt)"

cd "$dir"

BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
CIBW_DEBUG_KEEP_CONTAINER="${CIBW_DEBUG_KEEP_CONTAINER:-0}"

# Build bindings, first fill cache, then build bindings per python version
# Note that there is an issue with python 3.13, skipped
env \
    CIBW_PLATFORM='linux' \
    CIBW_ARCHS='x86_64' \
    CIBW_BUILD='cp310-manylinux* cp311-manylinux* cp312-manylinux*' \
    CIBW_PROJECT_REQUIRES_PYTHON='>=3.10' \
    CIBW_MANYLINUX_X86_64_IMAGE='manylinux_2_28' \
    CIBW_BEFORE_ALL='./install-build-tools.sh && ./update-ccache-from-host.sh' \
    CIBW_BEFORE_BUILD='rm -rf python_bindings/mlir python_bindings/dist python_bindings/build python_bindings/*egg-info && env BUILD_LLVM_COMPONENTS=mlir_bindings BUILD_LLVM_MLIR_BINDINGS=1 BUILD_LLVM_TOOLS=0 ./build-mlir-bindings.sh && mv install-bindings/mlir python_bindings/' \
    CIBW_TEST_COMMAND='{package}/test-installed.sh' \
    BUILD_LLVM_REVISION="$BUILD_LLVM_REVISION" \
    BUILD_LLVM_CLEAN_BUILD_DIR="$BUILD_LLVM_CLEAN_BUILD_DIR" \
    CIBW_ENVIRONMENT_PASS_LINUX="BUILD_LLVM_CLEAN_BUILD_DIR BUILD_LLVM_REVISION" \
    CIBW_BUILD_VERBOSITY=1 \
    CIBW_DEBUG_KEEP_CONTAINER="$CIBW_DEBUG_KEEP_CONTAINER" \
    cibuildwheel \
    python_bindings

#    CIBW_DEBUG_KEEP_CONTAINER=1 \
