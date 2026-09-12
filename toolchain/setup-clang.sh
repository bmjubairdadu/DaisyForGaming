#!/bin/bash
# Setup Proton Clang (host tools) for DaisyForGaming 4.9.337 (daisy/msm8953)
# Kernel itself compiles with system GCC cross (era-correct for 4.9).
set -e
BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
CLANG_DIR="$BASE_DIR/toolchain/proton-clang"
if [ ! -d "$CLANG_DIR/bin" ] || [ -z "$(ls -A "$CLANG_DIR/bin" 2>/dev/null)" ]; then
  rm -rf "$CLANG_DIR"
  git clone --depth=1 https://github.com/kdrag0n/proton-clang.git "$CLANG_DIR"
else
  echo "Proton Clang exists - skipping clone"
fi
echo "Toolchain ready: $CLANG_DIR"
echo "Also install cross GCC: sudo apt install gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi"
