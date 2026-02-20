#!/usr/bin/env bash
set -euo pipefail
set -x

python -c 'from mlir.dialects.transform import structured'

echo "ALL TESTS PASSED"
