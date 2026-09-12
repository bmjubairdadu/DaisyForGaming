#!/bin/bash
# Apply all repo patches to the kernel tree (idempotent, safe to re-run).
# Usage: bash scripts/apply-tree-patches.sh [path/to/kernel_source]
set -e
S="${1:-/root/daisy-build/kernel_source}"
D="$(cd "$(dirname "$0")/.." && pwd)"
echo "[*] Applying repo patches to $S ..."
for p in "$D/patches"/*.patch; do
  [ -f "$p" ] || continue
  name="$(basename "$p")"
  if patch -d "$S" -p1 -R --dry-run < "$p" >/dev/null 2>&1; then
    echo "[*] already applied (skip): $name"
  elif patch -d "$S" -p1 -N --dry-run < "$p" >/dev/null 2>&1; then
    patch -d "$S" -p1 < "$p"
    echo "[*] applied: $name"
  else
    echo "[X] patch does not apply (mismatch, needs refresh): $name" >&2
    exit 1
  fi
done
echo "[*] KALLSYMS_ALL rule now:"
grep -n -A2 'config KALLSYMS_ALL' "$S/init/Kconfig"
echo "[*] config_data.gz rule now:"
grep -n 'config_data.gz:' "$S/kernel/Makefile"
echo "[*] LDS KEEP lines:"
grep -n 'kallsyms_lookup_name\|kallsyms_on_each_symbol' "$S/arch/arm64/kernel/vmlinux.lds.S" || echo "[!] LDS KEEP missing"
