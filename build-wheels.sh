#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(realpath -e "$(dirname "$0")")"

BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
BUILD_LLVM_CCACHE="${BUILD_LLVM_CCACHE:-0}"
BUILD_LLVM_REVISION="$(cat "$dir"/llvm_revision.txt)"

cd "$dir"

# Note: we build only cp310-manylinux because the genrated package
# is not python version/abi dependent, only platform dependent,
# hence it is not necessary to build one for each python version.
# The setup.py script enforce the py3-none-manylinux* naming.

env \
    CIBW_PLATFORM='linux' \
    CIBW_ARCHS='x86_64' \
    CIBW_BUILD='cp310-manylinux*' \
    CIBW_PROJECT_REQUIRES_PYTHON='>=3.10' \
    CIBW_MANYLINUX_X86_64_IMAGE='manylinux_2_28' \
    CIBW_BEFORE_ALL='./install-build-tools.sh && ./build-mlir-bindings.sh' \
    CIBW_TEST_COMMAND='{package}/test-installed.sh' \
    BUILD_LLVM_CLEAN_BUILD_DIR="$BUILD_LLVM_CLEAN_BUILD_DIR" \
    BUILD_LLVM_CCACHE="$BUILD_LLVM_CCACHE" \
    BUILD_LLVM_REVISION="$BUILD_LLVM_REVISION" \
    CIBW_ENVIRONMENT_PASS_LINUX="BUILD_LLVM_CLEAN_BUILD_DIR BUILD_LLVM_CCACHE BUILD_LLVM_REVISION" \
    cibuildwheel \
    .

#    CIBW_DEBUG_KEEP_CONTAINER=1 \
#    CIBW_BUILD_VERBOSITY=1 \

# Now install python_bindings
env \
    CIBW_PLATFORM='linux' \
    CIBW_ARCHS='x86_64' \
    CIBW_BUILD='cp3*-manylinux*' \
    CIBW_PROJECT_REQUIRES_PYTHON='>=3.10' \
    CIBW_MANYLINUX_X86_64_IMAGE='manylinux_2_28' \
    CIBW_TEST_COMMAND='{package}/test-installed.sh' \
    BUILD_LLVM_REVISION="$BUILD_LLVM_REVISION" \
    CIBW_ENVIRONMENT_PASS_LINUX="BUILD_LLVM_REVISION" \
    cibuildwheel \
    python_bindings
