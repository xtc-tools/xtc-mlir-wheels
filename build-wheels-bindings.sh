#!/usr/bin/env bash
set -euo pipefail
set -x

dir="$(dirname "$(readlink -f "$0")")"
BUILD_LLVM_REVISION="$(cat "$dir"/llvm_revision.txt)"

cd "$dir"

BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
CIBW_DEBUG_KEEP_CONTAINER="${CIBW_DEBUG_KEEP_CONTAINER:-0}"

BUILD_PLATFORM="${BUILD_PLATFORM:-linux}"

CIBW_PLATFORM='linux'
CIBW_ARCHS='x86_64'
# Note that the llvm build 1.19.x is not compatible with python 3.13/3.14
# hence we can't build for these python versions. Need to move to llvm >=1.21.
CIBW_BUILD='cp310-manylinux* cp311-manylinux* cp312-manylinux*'
CIBW_MANYLINUX_IMAGE='manylinux_2_28'
CIBW_CONTAINER_ENGINE_ARG="" 
CIBW_ENVIRONMENT_PASS=""     

CIBW_PROJECT_REQUIRES_PYTHON='>=3.10'
CIBW_TEST_COMMAND='{package}/test-installed.sh'
CIBW_BEFORE_BUILD='rm -rf python_bindings/mlir python_bindings/dist python_bindings/build python_bindings/*egg-info && env BUILD_LLVM_COMPONENTS=mlir_bindings BUILD_LLVM_MLIR_BINDINGS=1 BUILD_LLVM_TOOLS=0 ./build-mlir-bindings.sh && mv install-bindings/mlir python_bindings/'
CIBW_BEFORE_ALL="env BUILD_PLATFORM=$BUILD_PLATFORM ./install-build-tools.sh && ./update-ccache-from-host.sh"

if [ "$BUILD_PLATFORM" = "linux" ]; then
    CIBW_CONTAINER_ENGINE_ARG="CIBW_CONTAINER_ENGINE=docker"

elif [ "$BUILD_PLATFORM" = "darwin" ]; then
    CIBW_BUILD='cp310-macosx_arm64 cp311-macosx_arm64 cp312-macosx_arm64'
    CIBW_PLATFORM='macos'
    CIBW_ARCHS='arm64'
    CIBW_MANYLINUX_IMAGE=""
else
    echo "Error: Unknown BUILD_PLATFORM '$BUILD_PLATFORM'. Must be 'linux' or 'darwin'."
    exit 1
fi

ENV_VARS=(
    CIBW_PLATFORM="$CIBW_PLATFORM"
    CIBW_ARCHS="$CIBW_ARCHS"
    MACOSX_DEPLOYMENT_TARGET=15.0
    CIBW_BUILD="$CIBW_BUILD"
    CIBW_PROJECT_REQUIRES_PYTHON="$CIBW_PROJECT_REQUIRES_PYTHON"
    CIBW_MANYLINUX_X86_64_IMAGE="$CIBW_MANYLINUX_IMAGE"
    CIBW_BEFORE_ALL="$CIBW_BEFORE_ALL"
    CIBW_BEFORE_BUILD="$CIBW_BEFORE_BUILD"
    CIBW_TEST_COMMAND="$CIBW_TEST_COMMAND"
    CIBW_BEFORE_TEST="./install-llvm.sh"
    CIBW_REPAIR_WHEEL_COMMAND_MACOS="pip install wheel && python mac-os-wheels-fixer.py --original {wheel} --output {dest_dir}"
    BUILD_LLVM_REVISION="$BUILD_LLVM_REVISION"
    BUILD_LLVM_CLEAN_BUILD_DIR="$BUILD_LLVM_CLEAN_BUILD_DIR" \
    CIBW_ENVIRONMENT_PASS_LINUX="BUILD_LLVM_CLEAN_BUILD_DIR BUILD_LLVM_REVISION" \
    CIBW_BUILD_VERBOSITY=1 \
    CIBW_DEBUG_KEEP_CONTAINER="$CIBW_DEBUG_KEEP_CONTAINER" \
)

if [ -n "$CIBW_CONTAINER_ENGINE_ARG" ]; then
    ENV_VARS+=("$CIBW_CONTAINER_ENGINE_ARG")
fi

env "${ENV_VARS[@]}" \
    cibuildwheel \
    python_bindings
