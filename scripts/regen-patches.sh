#!/bin/bash
# Regenerate repo patch files from the live tree diff (clean LF, correct hunks)
set -e
S=/root/daisy-build/kernel_source
P=/mnt/d/Kernel/patches
cd "$S"
git diff init/Kconfig > "$P/kallsyms-all-legacy.patch"
git diff kernel/Makefile > "$P/ikconfig-embedded-fix.patch"
git diff kernel/kallsyms.c > "$P/keep-kallsyms-lookup.patch"
echo "=== regenerated ==="
ls -l "$P"
echo "=== verify each applies reverse (proof they match tree) ==="
for f in kallsyms-all-legacy.patch ikconfig-embedded-fix.patch keep-kallsyms-lookup.patch; do
  if patch -p1 -R --dry-run < "$P/$f" >/dev/null 2>&1; then
    echo "OK(match): $f"
  else
    echo "MISMATCH: $f"
  fi
done
echo "=== file endings ==="
file "$P"/*.patch
