#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(realpath -e "$(dirname "$0")")"

cd llvm-project

mkdir build
cmake \
    -DCMAKE_INSTALL_PREFIX="$dir"/install \
    -DLLVM_ENABLE_PROJECTS="" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -G Ninja \
    -B build llvm

ninja -C build
ninja -C build install
