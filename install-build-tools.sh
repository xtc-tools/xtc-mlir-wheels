#!/usr/bin/env bash
set -euo pipefail
set -x

# suppose already installed on MacOS
[ "$BUILD_PLATFORM" != "darwin" ] || exit 0

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"

BUILD_ARCH="${BUILD_ARCH:-$(uname -m)}"
case "$BUILD_ARCH" in
    x86_64|amd64)
        NINJA_URL_SUFFIX=""
        CUDA_REPO_ARCH="x86_64"
        CUDA_PKG_ARCH="x86_64"
        ;;
    aarch64|arm64)
        NINJA_URL_SUFFIX="-aarch64"
        CUDA_REPO_ARCH="sbsa"
        CUDA_PKG_ARCH="aarch64"
        ;;
    *)
        echo "Error: Unsupported architecture '$BUILD_ARCH'. Must be 'x86_64' or 'aarch64'."
        exit 1
        ;;
esac

CCACHE_VERSION=4.10.2
CCACHE_URL="https://github.com/ccache/ccache/releases/download/v$CCACHE_VERSION/ccache-$CCACHE_VERSION-linux-x86_64.tar.xz"

NINJA_VERSION=1.12.1
NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux$NINJA_URL_SUFFIX.zip"

CUDA_VERSION=12-9
CUDA_URL="https://developer.download.nvidia.com/compute/cuda/repos/rhel8/$CUDA_REPO_ARCH/cuda-rhel8.repo"

mkdir -p "$INSTALL_PREFIX/bin"
mkdir tmp.ninja
cd tmp.ninja
curl -L -o ninja-linux.zip "$NINJA_URL"
unzip ninja-linux.zip
cd ..
cp tmp.ninja/ninja "$INSTALL_PREFIX/bin"
chmod +x "$INSTALL_PREFIX/bin"/ninja
rm -rf tmp.ninja

# ccache only ships prebuilt x86_64 binaries for this (older) version; on
# other architectures (e.g. aarch64) fall back to the system package manager.
if [ "$BUILD_ARCH" = "x86_64" ] || [ "$BUILD_ARCH" = "amd64" ]; then
    mkdir tmp.ccache
    cd tmp.ccache
    curl -L -o ccache.tar.xz "$CCACHE_URL"
    tar xvJf ccache.tar.xz
    cd ..
    cp tmp.ccache/ccache*/ccache "$INSTALL_PREFIX/bin"
    rm -rf tmp.ccache
elif ! command -v ccache >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y ccache
    fi
    if ! command -v ccache >/dev/null 2>&1; then
        echo "Error: ccache is required on '$BUILD_ARCH' but was not found on the PATH," \
             "and could not be installed automatically." \
             "Please install it (e.g. via the system package manager) before building."
        exit 1
    fi
fi

if [ "${BUILD_CUDA_TOOLS-1}" = 1 ]; then
    echo "keepcache=True" >>/etc/dnf/dnf.conf
    dnf config-manager --add-repo "$CUDA_URL"
    dnf -y install cuda-compiler-"$CUDA_VERSION"."$CUDA_PKG_ARCH" \
        cuda-libraries-"$CUDA_VERSION"."$CUDA_PKG_ARCH" \
        cuda-libraries-devel-"$CUDA_VERSION"."$CUDA_PKG_ARCH"
    dnf clean all
fi

