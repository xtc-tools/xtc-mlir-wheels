#!/usr/bin/env bash
set -euo pipefail
set -x

# suppose already installed on MacOS
[ "$BUILD_PLATFORM" != "darwin" ] || exit 0

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
CCACHE_VERSION=4.10.2
CCACHE_URL="https://github.com/ccache/ccache/releases/download/v$CCACHE_VERSION/ccache-$CCACHE_VERSION-linux-x86_64.tar.xz"

NINJA_VERSION=1.12.1
NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip"

CUDA_VERSION=12-9
CUDA_URL="https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo"

mkdir -p "$INSTALL_PREFIX/bin"
mkdir tmp.ninja
cd tmp.ninja
curl -L -o ninja-linux.zip "$NINJA_URL"
unzip ninja-linux.zip
cd ..
cp tmp.ninja/ninja "$INSTALL_PREFIX/bin"
chmod +x "$INSTALL_PREFIX/bin"/ninja
rm -rf tmp.ninja

mkdir tmp.ccache
cd tmp.ccache
curl -L -o ccache.tar.xz "$CCACHE_URL"
tar xvJf ccache.tar.xz
cd ..
cp tmp.ccache/ccache*/ccache "$INSTALL_PREFIX/bin"
rm -rf tmp.ccache

if [ "${BUILD_CUDA_TOOLS-1}" = 1 ]; then
    echo "keepcache=True" >>/etc/dnf/dnf.conf
    dnf config-manager --add-repo "$CUDA_URL"
    dnf -y install cuda-compiler-"$CUDA_VERSION".x86_64 \
        cuda-libraries-"$CUDA_VERSION".x86_64 \
        cuda-libraries-devel-"$CUDA_VERSION".x86_64
    dnf clean all
fi

