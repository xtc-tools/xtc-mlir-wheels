#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(realpath -e "$(dirname "$0")")"

BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
LLVM_TARGETS_TO_BUILD="${LLVM_TARGETS_TO_BUILD-AArch64;ARM;X86}"
LLVM_BUILD_TOOLS="${LLVM_BUILD_TOOLS:-OFF}"

cd llvm-project

mkdir build
cmake \
    -DCMAKE_INSTALL_PREFIX="$dir"/install \
    -DLLVM_ENABLE_PROJECTS="" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON \
    -DLLVM_TARGETS_TO_BUILD="$LLVM_TARGETS_TO_BUILD" \
    -DLLVM_BUILD_TOOLS="$LLVM_BUILD_TOOLS" \
    -G Ninja \
    -B build llvm

ninja -C build
ninja -C build install

[ "$BUILD_LLVM_CLEAN_BUILD_DIR" != 1 ] || rm -rf build
