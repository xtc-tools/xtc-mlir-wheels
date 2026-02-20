#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

LLVM_REVISION="$(cat "$dir"/llvm_revision.txt)"

mkdir -p llvm-project
cd llvm-project
git init
git config --local user.email "CIBOT@noreply.com"
git config --local user.name "CI BOT"
git remote add origin https://github.com/llvm/llvm-project
git fetch --depth 1 origin "$LLVM_REVISION"
git reset --hard FETCH_HEAD
git submodule init
git submodule update --recursive --depth 1

# Apply patches with git and reset to fetched revision
if [ -d "$dir"/patches/llvm ]; then
    for patch in "$dir"/patches/llvm/*.patch; do
        git am "$patch"
    done
fi
git reset FETCH_HEAD
