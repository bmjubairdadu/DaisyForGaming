#!/bin/bash
C=/root/daisy-build/kernel_source/out/.config
grep -E "MODULES" "$C" | head -5
echo "---"
grep -E "OVERLAY" "$C" | head -3
echo "---"
grep -E "KALLSYMS" "$C"
