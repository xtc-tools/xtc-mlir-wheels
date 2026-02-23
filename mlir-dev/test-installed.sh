#!/usr/bin/env bash
set -euo pipefail
set -x

PREFIX="$(python -c 'import mlir;print(mlir.__path__[0])')"
[ -d "$PREFIX/include" ] || exit 1
[ -d "$PREFIX/lib/cmake/mlir" ] || exit 1

echo "ALL TESTS PASSED"
