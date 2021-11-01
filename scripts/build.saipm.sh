#!/bin/bash

PLATFORM=$1
RELEASE_DIR=$2
TOOLCHAIN_FILE=$3
OPENSSL_ROOT=$4

echo "Release Dir: $RELEASE_DIR"
echo "Boost Root: $BOOST_ROOT"
echo "OpenSSL Root: $OPENSSL_ROOT"
echo "C++ REST SDK: $CPPRESTSDK_ROOT"
echo "Toolchain: $TOOLCHAIN_FILE"
echo "SignalR: $SIGNALR_ROOT"

if [[ -z $SAIPM_BUILD_MODE ]]; then
    echo "Value of 'SAIPM_BUILD_MODE' is not set"
    exit 1
else
    BUILD_TYPE=$SAIPM_BUILD_MODE # set by saipm
fi

# Cross-platform CPU count for parallel build
NCPU=$(($(nproc) - 1))
if [ $NCPU -le 0 ]; then
    NCPU=1
fi
echo "Parallel Jobs: $NCPU"
echo

WORK_ROOT=$(pwd)
echo "Work root: $WORK_ROOT"

# Prepare for Build
echo "Created new build directory..."
BUILD_DIR="$WORK_ROOT/build.$PLATFORM"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

set -x
cmake \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DBUILD_SHARED_LIBS=0 \
    -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT" \
    -DOPENSSL_INCLUDE_DIR="$OPENSSL_ROOT/include" \
    -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_ROOT/lib/libcrypto.a" \
    ..
RET_CODE=$?
set +x
if [[ $RET_CODE -ne 0 ]]; then
    exit $RET_CODE
else
    echo "[socket-io-client-cpp] cmake... Done."
fi

set -x
make -j$NCPU
RET_CODE=$?
set +x
if [[ $RET_CODE -ne 0 ]]; then
    exit $RET_CODE
else
    echo "[socket-io-client-cpp] make... Done."
fi

echo "Copying files to release path..."
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR/lib" "$RELEASE_DIR/include"

cp -v "$BUILD_DIR/libsioclient.a" "$RELEASE_DIR/lib"
cp -vr "$WORK_ROOT/src/"*.h "$RELEASE_DIR/include"

echo "Done."
