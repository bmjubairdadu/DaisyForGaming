#!/bin/bash
cd /mnt/d/DaisyForGaming
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 KBUILD_BUILD_USER=daisy KBUILD_BUILD_HOST=daisy
BEFORE=$(stat -c '%Y' out/arch/arm64/boot/Image.gz-dtb 2>/dev/null || echo 0)
for i in 1 2 3 4 5 6; do
  timeout 560 make O=out ARCH=arm64 -j8 > /tmp/rb_loop.log 2>&1
  rc=$?
  errs=$(grep -cE 'error:' /tmp/rb_loop.log)
  echo "round $i: exit=$rc errors=$errs"
  if [ "$errs" != "0" ]; then
    grep -E 'error:' /tmp/rb_loop.log | head -8
    break
  fi
  AFTER=$(stat -c '%Y' out/arch/arm64/boot/Image.gz-dtb 2>/dev/null || echo 0)
  if [ "$AFTER" != "$BEFORE" ]; then
    echo "IMAGE_REBUILT"
    break
  fi
  if [ $rc -eq 0 ]; then
    echo "make clean exit"
    break
  fi
done
tail -3 /tmp/rb_loop.log
stat -c '%y' out/arch/arm64/boot/Image.gz-dtb
echo LOOP_DONE
