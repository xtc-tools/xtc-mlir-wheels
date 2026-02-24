#!/usr/bin/env bash
set -euo pipefail
set -x
dir="$(dirname "$(readlink -f "$0")")"

# dump env
env | sort

# Dump ccache
ccache -sv || true

BUILD_DIR="${1-llvm-project/mlir/build}"
INSTALL_DIR="${2-$dir/mlir-tools/install}"
INSTALL_BINDINGS_DIR="${3-$dir/mlir-python-bindings/install}"
INSTALL_DEV_DIR="${3-$dir/mlir-dev/install}"

BUILD_LLVM_CLEAN_BUILD_DIR="${BUILD_LLVM_CLEAN_BUILD_DIR:-1}"
BUILD_LLVM_CLEAN_BUILD_DIR_POST="${BUILD_LLVM_CLEAN_BUILD_DIR_POST:-0}"
BUILD_LLVM_CCACHE="${BUILD_LLVM_CCACHE:-1}"
BUILD_LLVM_MLIR_BINDINGS="${BUILD_LLVM_MLIR_BINDINGS:-0}"
LLVM_TARGETS_TO_BUILD="${LLVM_TARGETS_TO_BUILD-AArch64;ARM;X86;NVPTX}"

BUILD_CUDA_TOOLS="${BUILD_CUDA_TOOLS:-1}"
MLIR_CUDA_OPTIONS=""
if [ "$BUILD_CUDA_TOOLS" = 1 ]; then
    # source Cuda toolkit
    export PATH="$PATH:/usr/local/cuda/bin"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64"
    MLIR_CUDA_OPTIONS="-DMLIR_ENABLE_CUDA_RUNNER=ON -DMLIR_NVVM_EMBED_LIBDEVICE=ON"
fi

MLIR_INSTALL_RPATH=""
if [ "$BUILD_PLATFORM" = "linux" ]; then
    MLIR_INSTALL_RPATH='-DCMAKE_INSTALL_RPATH=$ORIGIN:$ORIGIN/../lib:$ORIGIN/../../llvm/lib'
fi

LLVM_BUILD_TYPE="Release" # "MinSizeRel"

CCACHE_OPTS=""
[ "$BUILD_LLVM_CCACHE" != 1 ] || CCACHE_OPTS="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"

if [ "$BUILD_LLVM_MLIR_BINDINGS" = 1 ]; then
    MLIR_BINDINGS="-DMLIR_ENABLE_BINDINGS_PYTHON=ON -DMLIR_LINK_MLIR_DYLIB=OFF"
else
    MLIR_BINDINGS="-DMLIR_ENABLE_BINDINGS_PYTHON=OFF -DMLIR_LINK_MLIR_DYLIB=ON"
fi

[ "$BUILD_LLVM_CLEAN_BUILD_DIR" != 1 ] || rm -rf "$BUILD_DIR"
rm -rf "$INSTALL_DIR" "$INSTALL_BINDINGS_DIR" "$INSTALL_DEV_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_BINDINGS_DIR"
mkdir -p "$INSTALL_DEV_DIR"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

which python3
python3 --version

LLVM_PREFIX="$(python3 -c 'import llvm;print(llvm.__path__[0])')"

python3 -m pip install -r "$dir"/llvm-project/mlir/python/requirements.txt
python3 -m pip list

cmake \
    -DLLVM_DIR="$LLVM_PREFIX"/lib/cmake/llvm \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    $MLIR_INSTALL_RPATH \
    -DCMAKE_BUILD_TYPE="$LLVM_BUILD_TYPE" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_ENABLE_WARNINGS=OFF \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON \
    -DLLVM_TARGETS_TO_BUILD="$LLVM_TARGETS_TO_BUILD" \
    -DLLVM_BUILD_TOOLS=ON \
    -DLLVM_BUILD_UTILS=ON \
    -DLLVM_ENABLE_ZLIB=OFF \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DMLIR_INCLUDE_INTEGRATION_TESTS=OFF \
    -DMLIR_INCLUDE_TESTS=OFF \
    -DMLIR_BUILD_MLIR_C_DYLIB=ON \
    -DMLIR_ENABLE_EXECUTION_ENGINE=ON \
    -DMLIR_ENABLE_SPIRV_CPU_RUNNER=ON \
    $MLIR_CUDA_OPTIONS \
    $MLIR_BINDINGS \
    $CCACHE_OPTS \
    -Wno-dev \
    -Wno-deprecated \
    -G Ninja \
    ..

ninja
ninja install

if [ -d "$INSTALL_DIR"/lib ]; then
    # remove useless so links
    find "$INSTALL_DIR"/lib/ -type l -name '*.so' | xargs rm -f
    find "$INSTALL_DIR"/lib/ -type l -name '*.dylib' | xargs rm -f
fi

mkdir -p "$INSTALL_DEV_DIR"
mv "$INSTALL_DIR"/include "$INSTALL_DEV_DIR"/
mkdir -p "$INSTALL_DEV_DIR"/lib
mv "$INSTALL_DIR"/lib/*.a "$INSTALL_DEV_DIR"/lib/
mv "$INSTALL_DIR"/lib/cmake "$INSTALL_DEV_DIR"/lib/
mv "$INSTALL_DIR"/lib/objects-* "$INSTALL_DEV_DIR"/lib/
mkdir -p "$INSTALL_DEV_DIR"/bin
mv "$INSTALL_DIR"/bin/tblgen-* "$INSTALL_DEV_DIR"/bin/

if [ -d "$INSTALL_DIR"/python_packages ]; then
    # Python bindings
    mv "$INSTALL_DIR"/python_packages/mlir_core/mlir "$INSTALL_BINDINGS_DIR"/
    rm -rf "$INSTALL_DIR"/python_packages
    ! [ -f "$INSTALL_BINDINGS_DIR"/mlir/_mlir_libs/libMLIRPythonCAPI.so ] || \
        patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib:$ORIGIN/../../llvm/lib' "$INSTALL_BINDINGS_DIR"/mlir/_mlir_libs/libMLIRPythonCAPI.so
fi

cd "$dir"
[ "$BUILD_LLVM_CLEAN_BUILD_DIR_POST" != 1 ] || rm -rf "$BUILD_DIR"


#    -DCMAKE_VISIBILITY_INLINES_HIDDEN=ON \
    #    -DCMAKE_C_VISIBILITY_PRESET=hidden \
    #    -DCMAKE_CXX_VISIBILITY_PRESET=hidden \

# -DLLVM_TOOL_LLVM_DRIVER_BUILD=OFF \
    # -DLLVM_TOOL_LTO_BUILD=OFF \
    # -DLLVM_TOOL_GOLD_BUILD=OFF \
    # -DLLVM_TOOL_LLVM_AR_BUILD=OFF \
    # -DLLVM_TOOL_LLVM_AR_BUILD=OFF \
    # -DLLVM_TOOL_LLVM_LTO_BUILD=OFF \
    # -DLLVM_TOOL_LLVM_PROFDATA_BUILD=OFF \
    # -DLLVM_TOOL_LLD_BUILD=OFF \
    # -DLLVM_TOOL_CLANG_BUILD=OFF \
    # -DLLVM_TOOL_FLANG_BUILD=OFF \
    # -DLLVM_TOOL_LLDB_BUILD=OFF \
    # -DLLVM_TOOL_BOLT_BUILD=OFF \
    # -DLLVM_TOOL_POLLY_BUILD=OFF \
    # -DLLVM_TOOL_LIBCLC_BUILD=OFF \
    # -DLLVM_TOOL_LLVM_CONFIG_BUILD=ON \
    # -DLLVM_TOOL_MLIR_BUILD=ON \
