#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

cd "$dir"

BUILD_PLATFORM="${BUILD_PLATFORM:-linux}"

BUILD_BINDINGS="${BUILD_BINDINGS-}"

CIBW_PLATFORM="linux"
CIBW_ARCHS="x86_64"
CIBW_BUILD="cp310-manylinux*"
CIBW_MANYLINUX_IMAGE="manylinux_2_28"

BUILD_TARGET_NVPTX="${BUILD_TARGET_NVPTX:-1}"
BUILD_LLVM_DEBUG_TARGET="${BUILD_LLVM_DEBUG_TARGET:-}"
BUILD_VERBOSITY="${BUILD_VERBOSITY:-0}"
BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
CIBW_DEBUG_KEEP_CONTAINER="${CIBW_DEBUG_KEEP_CONTAINER:-0}"
BUILD_CCACHE_DIR="${BUILD_CCACHE_DIR-}"
BUILD_PIP_CACHE_DIR="${BUILD_PIP_CACHE_DIR-}"

# One of: "", bins, default. Used to be bins, now "" (add default tools).
BUILD_LLVM_COMPONENTS=""

CIBW_BEFORE_BUILD="rm -rf dist build *egg-info"
CIBW_TEST_COMMAND="{package}/test-installed.sh"
CIBW_BEFORE_ALL="./install-build-tools.sh && env BUILD_LLVM_MLIR_BINDINGS=0 BUILD_LLVM_TOOLS=1 BUILD_LLVM_COMPONENTS=$BUILD_LLVM_COMPONENTS ./build-mlir-bindings.sh"

if [ "$BUILD_BINDINGS" ]; then
    CIBW_BUILD="cp310-manylinux* cp311-manylinux* cp312-manylinux* cp313-manylinux* cp314-manylinux*"
    CIBW_BEFORE_ALL="./install-build-tools.sh"
    CIBW_BEFORE_BUILD="rm -rf python_bindings/mlir python_bindings/dist python_bindings/build python_bindings/*egg-info && env BUILD_LLVM_COMPONENTS=mlir_bindings BUILD_LLVM_MLIR_BINDINGS=1 BUILD_LLVM_TOOLS=0 ./build-mlir-bindings.sh && mv install-bindings/mlir python_bindings/"
fi

CIBW_BEFORE_TEST=""
MACOSX_DEPLOYMENT_ARGS=""
CONTAINER_ENGINE_ARG=""
if [ "$BUILD_PLATFORM" = "linux" ]; then
    DOCKER_ARGS=""
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
    BUILD_TARGET_NVPTX=0
    CIBW_PLATFORM="macos"
    CIBW_ARCHS="arm64"
    CIBW_BUILD="cp310-*"
    [ -z "$BUILD_BINDINGS" ] || CIBW_BUILD="cp310-macosx_arm64 cp311-macosx_arm64 cp312-macosx_arm64 cp313-macosx_arm64 cp314-macosx_arm64"
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
    CIBW_PROJECT_REQUIRES_PYTHON=">=3.10"
    CIBW_MANYLINUX_X86_64_IMAGE="$CIBW_MANYLINUX_IMAGE"
    CIBW_BEFORE_ALL="$CIBW_BEFORE_ALL"
    CIBW_BEFORE_BUILD="$CIBW_BEFORE_BUILD"
    CIBW_BEFORE_TEST="$CIBW_BEFORE_TEST"
    CIBW_REPAIR_WHEEL_COMMAND_MACOS="pip install wheel && python mac-os-wheels-fixer.py --original {wheel} --output {dest_dir}"
    CIBW_REPAIR_WHEEL_COMMAND_LINUX="auditwheel repair --exclude 'libcuda.so.*' -w {dest_dir} {wheel}" \
    CIBW_TEST_COMMAND="$CIBW_TEST_COMMAND"
    BUILD_PLATFORM="$BUILD_PLATFORM"
    PIP_CACHE_DIR="$BUILD_PIP_CACHE_DIR"
    CCACHE_DIR="$BUILD_CCACHE_DIR"
    BUILD_LLVM_DEBUG_TARGET="$BUILD_LLVM_DEBUG_TARGET"
    BUILD_TARGET_NVPTX="$BUILD_TARGET_NVPTX"
    BUILD_LLVM_CLEAN_BUILD_DIR="$BUILD_LLVM_CLEAN_BUILD_DIR"
    CIBW_ENVIRONMENT_PASS="BUILD_LLVM_DEBUG_TARGET BUILD_LLVM_CLEAN_BUILD_DIR BUILD_PLATFORM PIP_CACHE_DIR CCACHE_DIR BUILD_TARGET_NVPTX"
    CIBW_BUILD_VERBOSITY="$BUILD_VERBOSITY"
    CIBW_DEBUG_KEEP_CONTAINER="$CIBW_DEBUG_KEEP_CONTAINER"
)

[ -z "$CONTAINER_ENGINE_ARG" ] || ENV_VARS+=("$CONTAINER_ENGINE_ARG")
[ -z "$MACOSX_DEPLOYMENT_ARGS" ] || ENV_VARS+=("$MACOSX_DEPLOYMENT_ARGS")

TARGET=.
[ -z "$BUILD_BINDINGS" ] || TARGET=python_bindings

env "${ENV_VARS[@]}" \
     cibuildwheel \
     $TARGET

