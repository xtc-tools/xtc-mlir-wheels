#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

exec env BUILD_PACKAGE=mlir-tools "$dir"/build-wheels.sh
