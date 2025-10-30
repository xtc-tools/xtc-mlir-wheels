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

BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
CIBW_DEBUG_KEEP_CONTAINER="${CIBW_DEBUG_KEEP_CONTAINER:-0}"

# Build bindings, need to rebuild for each python version, default is to use ccache,
# hence builds time are amortized.
# Note that there is an issue with python 3.13, skipped
env \
    CIBW_PLATFORM='linux' \
    CIBW_ARCHS='x86_64' \
    CIBW_BUILD='cp310-manylinux* cp311-manylinux* cp312-manylinux* cp313-manylinux* cp314-manylinux*' \
    CIBW_PROJECT_REQUIRES_PYTHON='>=3.10' \
    CIBW_MANYLINUX_X86_64_IMAGE='manylinux_2_28' \
    CIBW_CONTAINER_ENGINE="$CIBW_CONTAINER_ENGINE" \
    CIBW_BEFORE_ALL='./install-build-tools.sh' \
    CIBW_BEFORE_BUILD='rm -rf python_bindings/mlir python_bindings/dist python_bindings/build python_bindings/*egg-info && env BUILD_LLVM_COMPONENTS=mlir_bindings BUILD_LLVM_MLIR_BINDINGS=1 BUILD_LLVM_TOOLS=0 ./build-mlir-bindings.sh && mv install-bindings/mlir python_bindings/' \
    CIBW_TEST_COMMAND='{package}/test-installed.sh' \
    BUILD_LLVM_REVISION="$BUILD_LLVM_REVISION" \
    BUILD_LLVM_CLEAN_BUILD_DIR="$BUILD_LLVM_CLEAN_BUILD_DIR" \
    CCACHE_DIR="$DOCKER_CCACHE_DIR" \
    CIBW_ENVIRONMENT_PASS_LINUX="BUILD_LLVM_CLEAN_BUILD_DIR BUILD_LLVM_REVISION CCACHE_DIR" \
    CIBW_BUILD_VERBOSITY=1 \
    CIBW_DEBUG_KEEP_CONTAINER="$CIBW_DEBUG_KEEP_CONTAINER" \
    CIBW_REPAIR_WHEEL_COMMAND_LINUX="auditwheel repair --exclude 'libcuda.so.*' -w {dest_dir} {wheel}" \
    cibuildwheel \
    python_bindings

#    CIBW_DEBUG_KEEP_CONTAINER=1 \
