#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(realpath -e "$(dirname "$0")")"

BUILD_LLVM_REVISION="$(cat "$dir"/llvm_revision.txt)"

cd "$dir"

DOCKER_ARGS=""
DOCKER_CCACHE_DIR=""
if [ -n "$BUILD_CCACHE_DIR-}" ]; then
    mkdir -p "$BUILD_CCACHE_DIR"
    DOCKER_CCACHE_DIR="/ccache"
    DOCKER_ARGS="$DOCKER_ARGS -v'$BUILD_CCACHE_DIR:$DOCKER_CCACHE_DIR'"
fi
CIBW_CONTAINER_ENGINE="docker;create_args:$DOCKER_ARGS"

BUILD_LLVM_DEBUG_TARGET="${BUILD_LLVM_DEBUG_TARGET:-}"
BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
CIBW_DEBUG_KEEP_CONTAINER="${CIBW_DEBUG_KEEP_CONTAINER:-0}"

# One of: "", bins, default. Used to be bins, now "" (add default tools).
BUILD_LLVM_COMPONENTS=""

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
    CIBW_CONTAINER_ENGINE="$CIBW_CONTAINER_ENGINE" \
    CIBW_BEFORE_ALL="./install-build-tools.sh && env BUILD_LLVM_MLIR_BINDINGS=0 BUILD_LLVM_TOOLS=1 BUILD_LLVM_COMPONENTS=$BUILD_LLVM_COMPONENTS ./build-mlir-bindings.sh" \
    CIBW_BEFORE_BUILD="rm -rf dist build *egg-info" \
    CIBW_TEST_COMMAND='{package}/test-installed.sh' \
    BUILD_LLVM_DEBUG_TARGET="$BUILD_LLVM_DEBUG_TARGET" \
    BUILD_LLVM_CLEAN_BUILD_DIR="$BUILD_LLVM_CLEAN_BUILD_DIR" \
    BUILD_LLVM_REVISION="$BUILD_LLVM_REVISION" \
    CCACHE_DIR="$DOCKER_CCACHE_DIR" \
    CIBW_ENVIRONMENT_PASS_LINUX="BUILD_LLVM_DEBUG_TARGET BUILD_LLVM_CLEAN_BUILD_DIR BUILD_LLVM_REVISION CCACHE_DIR" \
    CIBW_BUILD_VERBOSITY=1 \
    CIBW_DEBUG_KEEP_CONTAINER="$CIBW_DEBUG_KEEP_CONTAINER" \
    cibuildwheel \
    .
