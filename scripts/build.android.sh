#!/bin/bash

RELEASE_DIR=$1
ANDROID_NDK_ROOT=$2
BUILD_DIR=$3
ANDROID_ABI=$4
API_LEVEL=$5

if [[ -z $SAIPM_BUILD_MODE ]]; then
    echo "Value of 'SAIPM_BUILD_MODE' is not set"
    exit 1
else
    BUILD_TYPE=$SAIPM_BUILD_MODE # set by saipm
fi

echo "Release Dir: $RELEASE_DIR"
echo "Android NDK Root: $ANDROID_NDK_ROOT"
echo "Build Dir: $BUILD_DIR"
echo "Android ABI: $ANDROID_ABI"
echo "API Level: $API_LEVEL"

PLATFORM=android

# Cross-platform CPU count for parallel build
NCPU=$(($(nproc) - 1))
if [ $NCPU -le 0 ]; then
    NCPU=1
fi
echo "Parallel Jobs: $NCPU"

WORK_ROOT=$(pwd)
echo "Work root: $WORK_ROOT"

# Initialize android specific configs
ANDROID_STL=c++_static # c++, gnustl, stlport, system, none
echo "Android STL: $ANDROID_STL"
echo

case $ANDROID_ABI in
arm64-v8a | armeabi-v7a)
    echo "Building for $ANDROID_ABI ..."
    ;;
*)
    echo "Unknown abi. Try arm64-v8a|armeabi-v7a"
    ;;
esac

# Prepare for Build
echo "Created new build directory..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

set -x
cmake \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
    -DCMAKE_ANDROID_NDK="$ANDROID_NDK_ROOT" \
    -DCMAKE_ANDROID_ARCH_ABI=$ANDROID_ABI \
    -DANDROID_NDK="$ANDROID_NDK_ROOT" \
    -DANDROID_ABI=$ANDROID_ABI \
    -DANDROID_PLATFORM=android-$API_LEVEL \
    -DANDROID_NATIVE_API_LEVEL=$API_LEVEL \
    -DCMAKE_SYSTEM_VERSION=$API_LEVEL \
    -DANDROID_STL=$ANDROID_STL \
    -DCMAKE_ANDROID_STL_TYPE=$ANDROID_STL \
    -DANDROID_TOOLCHAIN=clang \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DBUILD_SHARED_LIBS=0 \
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
INCLUDE_DIR=$RELEASE_DIR/android$API_LEVEL/include
LIBRARY_DIR=$RELEASE_DIR/android$API_LEVEL/lib/$ANDROID_ABI
mkdir -p "$LIBRARY_DIR" "$INCLUDE_DIR" "$INCLUDE_DIR"

cp "$BUILD_DIR/libsioclient.a" "$LIBRARY_DIR"
cp -r "$WORK_ROOT/src/"*.h "$INCLUDE_DIR"

echo "Done."
