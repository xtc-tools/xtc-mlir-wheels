#!/usr/bin/env bash
set -euo pipefail
set -x

PREFIX="$(python -c 'import mlir_dev;print(mlir_dev.__path__[0])')"
[ -d "$PREFIX/include" ] || exit 1

echo "ALL TESTS PASSED"
