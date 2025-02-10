#!/usr/bin/env bash
set -euo pipefail
set -x

PREFIX="$(python -c 'import mlir;print(mlir.__path__[0])')"
"$PREFIX"/bin/llvm-config --version
"$PREFIX"/bin/llvm-config --ldflags

[ "$("$PREFIX"/bin/llvm-config --prefix)" == "$PREFIX" ]

echo "ALL TESTS PASSED"
