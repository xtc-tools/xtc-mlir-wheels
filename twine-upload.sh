#!/usr/bin/env bash
set -euo pipefail

TWINE_REPOSITORY_URL="${TWINE_REPOSITORY_URL?}"

for file in "$@"; do
    (set -x; twine upload --verbose --non-interactive --repository-url "$TWINE_REPOSITORY_URL" "$file") || true
done
