#!/bin/bash
# Live progress for DaisyForGaming build - run anytime, safe (read-only)
LOG=/mnt/d/Kernel/out/build.log
OUT=/mnt/d/Kernel/kernel_source/out
echo "=== TIME ==="
date
echo ""
echo "=== BUILD.LOG (last 5 lines) ==="
tail -n 5 "$LOG" 2>&1
echo ""
CC_COUNT=$(grep -c "^  CC" "$LOG" 2>/dev/null || echo 0)
AR_COUNT=$(grep -c "^  AR" "$LOG" 2>/dev/null || echo 0)
LD_COUNT=$(grep -c "^  LD\|^  LINK\|^  LDS" "$LOG" 2>/dev/null || echo 0)
O_COUNT=$(find "$OUT" -name "*.o" 2>/dev/null | wc -l)
echo "Compiled so far: CC=$CC_COUNT AR=$AR_COUNT LINK=$LD_COUNT .o files=$O_COUNT"
echo ""
# Rough stage detection
if grep -q "Image.gz-dtb" "$LOG" 2>/dev/null && ls /mnt/d/Kernel/kernel_source/out/arch/arm64/boot/Image.gz-dtb >/dev/null 2>&1; then
  echo "STAGE: DONE - Image.gz-dtb ready!"
elif grep -q "LINK.*vmlinux\|LD.*vmlinux\|SYSMAP\|SORTEX\|KALLSYMS" "$LOG" 2>/dev/null | tail -1 | grep -q . ; then
  echo "STAGE: LINK (90%+) - vmlinux link / kallsyms / compress"
elif [ "$O_COUNT" -gt 3000 ]; then
  echo "STAGE: LATE (~75%) - fs/kernel/mm/sound linking soon"
elif [ "$O_COUNT" -gt 2000 ]; then
  echo "STAGE: MID (~50%) - drivers/net compiling"
else
  echo "STAGE: EARLY (<50%) - drivers compiling"
fi
echo ""
echo "=== STILL RUNNING? ==="
ps aux | grep -E "make.*Image.gz-dtb" | grep -v grep | head -n 3
if [ $? -ne 0 ]; then
  echo "(no make process = build finished or stopped)"
fi
echo ""
echo "=== OUTPUTS ==="
ls -lh /mnt/d/Kernel/out/ 2>&1
ls -lh /mnt/d/Kernel/kernel_source/out/arch/arm64/boot/Image.gz-dtb 2>&1
ls -lh /mnt/d/Kernel/out/*.zip 2>&1
