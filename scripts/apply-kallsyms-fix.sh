#!/bin/bash
set -e
S=/root/daisy-build/kernel_source
P=/mnt/d/Kernel/patches/kallsyms-all-legacy.patch

if ! grep -q '^+++\ b/init/Kconfig' "$P"; then
  echo "Invalid KALLSYMS patch"
  exit 1
fi
if grep -q 'depends on KALLSYMS$' "$S/init/Kconfig" && ! grep -q 'depends on DEBUG_KERNEL && KALLSYMS' "$S/init/Kconfig"; then
  echo "KALLSYMS_ALL dependency already fixed"
else
  patch -d "$S" -p1 < "$P"
fi
grep -n -A2 'config KALLSYMS_ALL' "$S/init/Kconfig"
