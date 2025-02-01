#!/usr/bin/env bash
set -euo pipefail
set -x

NINJA_VERSION=1.12.1
NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip"

mkdir tmp.ninja
cd tmp.ninja
curl -L -o ninja-linux.zip "$NINJA_URL"
unzip ninja-linux.zip
cp ninja /usr/local/bin
chmod +x /usr/local/bin/ninja
cd ..
rm -rf tmp.ninja
