#!/bin/bash
set -e
B=/root/daisy-build
S=$B/kernel_source
export PATH=/root/daisy-build/toolchain/proton-clang/bin:$PATH
dos2unix /mnt/d/Kernel/.ak3-custom/anykernel.sh /mnt/d/Kernel/.ak3-custom/version 2>/dev/null || sed -i 's/\r$//' /mnt/d/Kernel/.ak3-custom/anykernel.sh /mnt/d/Kernel/.ak3-custom/version
cp /mnt/d/Kernel/.ak3-custom/anykernel.sh /mnt/d/Kernel/.ak3-custom/version $B/AnyKernel3/ 2>/dev/null || true
if [ ! -d $B/AnyKernel3/.git ]; then
  rm -rf $B/AnyKernel3
  git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git $B/AnyKernel3
  cp /mnt/d/Kernel/.ak3-custom/anykernel.sh /mnt/d/Kernel/.ak3-custom/version $B/AnyKernel3/
fi
cp /mnt/d/Kernel/.ak3-custom/anykernel.sh /mnt/d/Kernel/.ak3-custom/version $B/AnyKernel3/
if [ -f /mnt/d/Kernel/.ak3-custom/thermal-engine-daisy-gaming.conf ]; then
  cp /mnt/d/Kernel/.ak3-custom/thermal-engine-daisy-gaming.conf $B/AnyKernel3/thermal-engine-daisy-gaming.conf
fi
DATE=$(date +%Y%m%d)
ZIP=DaisyForGaming-v2.2-Gaming-4.9.337-$DATE-AnyKernel3.zip
rm -rf $B/AK3-OUT
mkdir -p $B/AK3-OUT
cp -r $B/AnyKernel3/. $B/AK3-OUT/
rm -rf $B/AK3-OUT/.git
cp $S/out/arch/arm64/boot/Image.gz-dtb $B/AK3-OUT/Image.gz-dtb
mkdir -p $B/AK3-OUT/modules/vendor/etc
cp $B/AnyKernel3/thermal-engine-daisy-gaming.conf $B/AK3-OUT/modules/vendor/etc/ 2>/dev/null || true
python3 - $B/AK3-OUT/anykernel.sh <<'PYEOF'
import re, sys
p = sys.argv[1]
src = open(p).read()
src = re.sub(r"kernel\.string=.*",
             "kernel.string=DaisyForGaming by JUBAIR HOSEN - 4.9.337 Safe (No Pre-Root)", src)
open(p, "w").write(src)
PYEOF
rm -f $B/out/$ZIP
(cd $B/AK3-OUT && zip -r9 $B/out/$ZIP . -x '.git/*')
ls -lh $B/out/$ZIP
unzip -l $B/out/$ZIP | head -n 15
cp -v $B/out/$ZIP /mnt/d/Kernel/out/
echo ZIP22_OK
