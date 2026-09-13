#!/bin/bash
F=/home/jubair/daisy-build/AnyKernel3/tools/ak3-core.sh
echo "=== split_boot ==="
grep -n -A 22 "^split_boot" "$F" | head -n 30
echo ""
echo "=== write_boot ==="
grep -n -A 30 "^write_boot" "$F" | head -n 40
echo ""
echo "=== flash_boot ==="
grep -n -A 12 "^flash_boot" "$F" | head -n 18
echo ""
echo "=== dump_boot ==="
grep -n -A 35 "^dump_boot" "$F" | head -n 45
