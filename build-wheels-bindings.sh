#!/usr/bin/env bash
set -euo pipefail
set -x

dir="$(dirname "$(readlink -f "$0")")"

cd "$dir"

BUILD_PLATFORM="${BUILD_PLATFORM:-linux}"

CIBW_PLATFORM="linux"
CIBW_ARCHS="x86_64"
# Note that the llvm build 1.19.x is not compatible with python 3.13/3.14
# hence we can't build for these python versions. Need to move to llvm >=1.21.
CIBW_BUILD="cp310-manylinux* cp311-manylinux* cp312-manylinux*"
CIBW_MANYLINUX_IMAGE="manylinux_2_28"

BUILD_VERBOSITY="${BUILD_VERBOSITY:-0}"
BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
CIBW_DEBUG_KEEP_CONTAINER="${CIBW_DEBUG_KEEP_CONTAINER:-0}"

CIBW_PROJECT_REQUIRES_PYTHON=">=3.10"
CIBW_TEST_COMMAND="{package}/test-installed.sh"
CIBW_BEFORE_BUILD="rm -rf python_bindings/mlir python_bindings/dist python_bindings/build python_bindings/*egg-info && env BUILD_LLVM_COMPONENTS=mlir_bindings BUILD_LLVM_MLIR_BINDINGS=1 BUILD_LLVM_TOOLS=0 ./build-mlir-bindings.sh && mv install-bindings/mlir python_bindings/"
CIBW_BEFORE_ALL="./install-build-tools.sh"

CIBW_BEFORE_TEST=""
MACOSX_DEPLOYMENT_ARGS=""
CONTAINER_ENGINE_ARG=""
if [ "$BUILD_PLATFORM" = "linux" ]; then
    DOCKER_ARGS=""
    DOCKER_CCACHE_DIR=""
    if [ -n "$BUILD_PIP_CACHE_DIR" ]; then
        DOCKER_PIP_CACHE_DIR="/pip_cache"
        DOCKER_ARGS="$DOCKER_ARGS -v'$BUILD_PIP_CACHE_DIR:$DOCKER_PIP_CACHE_DIR'"
        BUILD_PIP_CACHE_DIR="$DOCKER_PIP_CACHE_DIR"
    fi
    if [ -n "$BUILD_CCACHE_DIR" ]; then
        DOCKER_CCACHE_DIR="/ccache"
        DOCKER_ARGS="$DOCKER_ARGS -v'$BUILD_CCACHE_DIR:$DOCKER_CCACHE_DIR'"
        BUILD_CCACHE_DIR="$DOCKER_CCACHE_DIR"
    fi
    CONTAINER_ENGINE_ARG="CIBW_CONTAINER_ENGINE=docker;create_args:$DOCKER_ARGS"
elif [ "$BUILD_PLATFORM" = "darwin" ]; then
    CIBW_BUILD="cp310-macosx_arm64 cp311-macosx_arm64 cp312-macosx_arm64"
    CIBW_PLATFORM="macos"
    CIBW_ARCHS="arm64"
    CIBW_MANYLINUX_IMAGE=""
    MACOSX_DEPLOYMENT_ARGS="MACOSX_DEPLOYMENT_TARGET=14.0" # supports macos14+
    CIBW_BEFORE_TEST="./install-llvm.sh"
else
    echo "Error: Unknown BUILD_PLATFORM '$BUILD_PLATFORM'. Must be 'linux' or 'darwin'."
    exit 1
fi

ENV_VARS=(
    CIBW_PLATFORM="$CIBW_PLATFORM"
    CIBW_ARCHS="$CIBW_ARCHS"
    CIBW_BUILD="$CIBW_BUILD"
    CIBW_PROJECT_REQUIRES_PYTHON="$CIBW_PROJECT_REQUIRES_PYTHON"
    CIBW_MANYLINUX_X86_64_IMAGE="$CIBW_MANYLINUX_IMAGE"
    CIBW_BEFORE_ALL="$CIBW_BEFORE_ALL"
    CIBW_BEFORE_BUILD="$CIBW_BEFORE_BUILD"
    CIBW_TEST_COMMAND="$CIBW_TEST_COMMAND"
    CIBW_BEFORE_TEST="$CIBW_BEFORE_TEST"
    CIBW_REPAIR_WHEEL_COMMAND_MACOS="pip install wheel && python mac-os-wheels-fixer.py --original {wheel} --output {dest_dir}"
    BUILD_PLATFORM="$BUILD_PLATFORM"
    PIP_CACHE_DIR="$BUILD_PIP_CACHE_DIR"
    CCACHE_DIR="$BUILD_CCACHE_DIR"
    BUILD_LLVM_CLEAN_BUILD_DIR="$BUILD_LLVM_CLEAN_BUILD_DIR" \
    CIBW_ENVIRONMENT_PASS="BUILD_LLVM_CLEAN_BUILD_DIR BUILD_PLATFORM PIP_CACHE_DIR CCACHE_DIR" \
    CIBW_BUILD_VERBOSITY="$BUILD_VERBOSITY" \
    CIBW_DEBUG_KEEP_CONTAINER="$CIBW_DEBUG_KEEP_CONTAINER" \
)

[ -z "$CONTAINER_ENGINE_ARG" ] || ENV_VARS+=("$CONTAINER_ENGINE_ARG")
[ -z "$MACOSX_DEPLOYMENT_ARGS" ] || ENV_VARS+=("$MACOSX_DEPLOYMENT_ARGS")

env "${ENV_VARS[@]}" \
    cibuildwheel \
    python_bindings
