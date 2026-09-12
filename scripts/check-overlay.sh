#!/bin/bash
S=/root/daisy-build/kernel_source
C="$S/out/.config"
echo "--- OVERLAY_FS Kconfig ---"
grep -rn "config OVERLAY_FS" "$S/fs/" | head -3
grep -n -B2 -A8 "config OVERLAY_FS" "$S/fs/overlayfs/Kconfig" 2>/dev/null | head -20
echo "--- FRAG asks? ---"
grep -n "OVERLAY" /mnt/d/Kernel/configs/daisy_gaming_defconfig
echo "--- OUT has? ---"
grep -n "OVERLAY_FS" "$C" || echo "MISSING in .config"
echo "--- olddefconfig would ask? deps check ---"
grep -E "OVERLAY_FS" "$S/fs/overlayfs/Kconfig" | head
