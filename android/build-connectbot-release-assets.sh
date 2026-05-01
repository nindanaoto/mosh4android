#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="${WORK_DIR:-"$ROOT_DIR/build/android-release"}"
CONNECTBOT_REPO="${CONNECTBOT_REPO:-https://github.com/nindanaoto/connectbot.git}"
CONNECTBOT_REF="${CONNECTBOT_REF:-mosh}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-24}"
ABIS="${ABIS:-arm64-v8a armeabi-v7a x86 x86_64}"

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  echo "ANDROID_NDK_HOME must point to an Android NDK installation" >&2
  exit 1
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

git clone --depth 1 --branch "$CONNECTBOT_REF" "$CONNECTBOT_REPO" "$WORK_DIR/connectbot"
rm -rf "$WORK_DIR/connectbot/libs/mosh"
mkdir -p "$WORK_DIR/connectbot/libs"
rsync -a --exclude .git "$ROOT_DIR/" "$WORK_DIR/connectbot/libs/mosh/"

for abi in $ABIS; do
  build_dir="$WORK_DIR/cmake-$abi"
  assets_dir="$WORK_DIR/assets-$abi"
  package_dir="$WORK_DIR/package-$abi"
  rm -rf "$build_dir" "$assets_dir" "$package_dir"
  mkdir -p "$assets_dir" "$package_dir"

  cmake -S "$WORK_DIR/connectbot/app" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$abi" \
    -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
    -DCONNECTBOT_BUILD_EMBEDDED_MOSH=ON \
    -DCMAKE_ANDROID_ASSETS_DIRECTORIES="$assets_dir"

  cmake --build "$build_dir" \
    --target zlib_external protoc_external protobuf_external ncurses_external nettle_external mosh_external \
    --parallel
  cmake --build "$build_dir" --target moshclient --parallel

  mosh_lib="$(find "$build_dir" -name libmoshclient.so -print -quit)"
  if [[ -z "$mosh_lib" ]]; then
    echo "Could not find libmoshclient.so for $abi" >&2
    exit 1
  fi

  cp "$mosh_lib" "$package_dir/libmosh-client.so"
  cp "$assets_dir/terminfo.zip" "$package_dir/terminfo.zip"

  (
    cd "$package_dir"
    zip -X -r "$WORK_DIR/mosh-android-$abi.zip" libmosh-client.so terminfo.zip
  )
done

ls -lh "$WORK_DIR"/mosh-android-*.zip
