#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(realpath -e "$(dirname "$0")")"

BUILD_LLVM_REVISION="$(cat "$dir"/llvm_revision.txt)"

cd "$dir"

# Build bindings, first fill cache, then build bindings per python version
env \
    CIBW_PLATFORM='linux' \
    CIBW_ARCHS='x86_64' \
    CIBW_BUILD='cp310-manylinux* cp311-manylinux*' \
    CIBW_PROJECT_REQUIRES_PYTHON='>=3.10' \
    CIBW_MANYLINUX_X86_64_IMAGE='manylinux_2_28' \
    CIBW_BEFORE_ALL='./install-build-tools.sh && env BUILD_LLVM_MLIR_BINDINGS=0 BUILD_LLVM_TOOLS=0 BUILD_LLVM_CCACHE=1 ./build-mlir-bindings.sh' \
    CIBW_BEFORE_BUILD='env BUILD_LLVM_MLIR_BINDINGS=1 BUILD_LLVM_TOOLS=0 BUILD_LLVM_CCACHE=1 ./build-mlir-bindings.sh && mv install-bindings/mlir python_bindings/' \
    CIBW_TEST_COMMAND='{package}/test-installed.sh' \
    BUILD_LLVM_REVISION="$BUILD_LLVM_REVISION" \
    CIBW_ENVIRONMENT_PASS_LINUX="BUILD_LLVM_REVISION" \
    CIBW_DEBUG_KEEP_CONTAINER=1 \
    CIBW_BUILD_VERBOSITY=1 \
    cibuildwheel \
    python_bindings

#    CIBW_DEBUG_KEEP_CONTAINER=1 \
#    CIBW_BUILD_VERBOSITY=1 \
