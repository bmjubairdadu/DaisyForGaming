#!/bin/bash
F=/home/jubair/daisy-build/AnyKernel3/tools/ak3-core.sh
echo "=== PROP CMDLINE FUNCS ==="
grep -n -E "^(patch_cmdline|patch_props|patch_prop|resetprop|patch_fstab|patch_ueventd|patch_initmodem)" "$F" | head -n 20
echo ""
echo "=== patch_cmdline body ==="
grep -n -A 12 "^patch_cmdline" "$F" | head -n 30
echo ""
echo "=== do.systemless handling ==="
grep -n -B2 -A8 "do.systemless" "$F" | head -n 60
echo ""
echo "=== modules handling ==="
grep -n -B2 -A6 "do.modules" "$F" | head -n 60
