#!/bin/bash
F=/home/jubair/daisy-build/AnyKernel3/tools/ak3-core.sh
echo "=== flash_boot full ==="
sed -n '314,420p' "$F"
