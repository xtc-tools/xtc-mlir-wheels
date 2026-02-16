#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

HOST_CCACHE_DIR="ccache"
if [ -d "$HOST_CCACHE_DIR" ]; then
    rm -rf /root/.cache/ccache
    mkdir -p /root/.cache
    cp -pr "$HOST_CCACHE_DIR" /root/.cache/ccache
fi
