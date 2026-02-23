#!/usr/bin/env bash
set -euo pipefail
set -x

PREFIX="$(python -c 'import mlir;print(mlir.__path__[0])')"
[ -f "$PREFIX"/lib/libMLIR.so ] || exit 1
[ -f "$PREFIX"/lib/libMLIR-C.so ] || exit 1

"$PREFIX"/bin/mlir-opt --version

echo "ALL TESTS PASSED"
