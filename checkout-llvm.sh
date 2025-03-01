#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(realpath -e "$(dirname "$0")")"

LLVM_REVISION="$(cat "$dir"/llvm_revision.txt)"

mkdir -p llvm-project
cd llvm-project
git init
git remote add origin https://github.com/llvm/llvm-project
git fetch --depth 1 origin "$LLVM_REVISION"
git reset --hard FETCH_HEAD
git submodule init
git submodule update --recursive --depth 1

if [ -d "$dir"/patches/llvm ]; then
    for patch in "$dir"/patches/llvm/*.patch; do
        patch -p1 <"$patch"
    done
fi
