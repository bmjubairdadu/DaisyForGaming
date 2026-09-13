#!/bin/bash
F=/home/jubair/daisy-build/AnyKernel3/tools/ak3-core.sh
echo "=== fingerprint / verifiedbootstate / flash.locked handling ==="
grep -n -i -E "fingerprint|verifiedbootstate|flash.locked|veritymode|isBuildConsistent|internal.problem" "$F" | head -n 40
echo ""
echo "=== patch_prop / resetprop funcs ==="
grep -n -A 10 "^patch_prop\|^resetprop\|resetprop " "$F" | head -n 60
echo ""
echo "=== PATCH_VBMETA_FLAG handling ==="
grep -n -B2 -A10 "PATCH_VBMETA_FLAG" "$F" | head -n 80
echo ""
echo "=== default.prop / prop.default handling ==="
grep -n -i -E "default.prop|prop.default|getprop|file_getprop.*fingerprint" "$F" | head -n 40
