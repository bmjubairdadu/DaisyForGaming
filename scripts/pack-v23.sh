#!/bin/bash
set -e
S=/root/daisy-build/kernel_source
D=/mnt/d/Kernel
AK3=/root/daisy-build/AnyKernel3
DATE=$(date +%Y%m%d)
ZNAME="DaisyForGaming-v1.2-Gaming-4.9.337-${DATE}-AnyKernel3.zip"
echo "=== 1. refresh AK3 ==="
if [ ! -d "$AK3/.git" ]; then
  rm -rf "$AK3"
  git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git "$AK3"
fi
cp "$D/.ak3-custom/anykernel.sh" "$AK3/anykernel.sh"
cp "$D/.ak3-custom/version" "$AK3/version" 2>/dev/null || true
echo "=== 2. pack ==="
rm -rf /root/daisy-build/AK3-OUT
mkdir -p /root/daisy-build/AK3-OUT
cp -r "$AK3"/. /root/daisy-build/AK3-OUT/
rm -rf /root/daisy-build/AK3-OUT/.git
cp "$S/out/arch/arm64/boot/Image.gz-dtb" /root/daisy-build/AK3-OUT/Image.gz-dtb
ls -lh /root/daisy-build/AK3-OUT/Image.gz-dtb
cd /root/daisy-build/AK3-OUT
rm -f "$D/out/$ZNAME" "$D/out/"DaisyForGaming-v2*.zip
zip -r9 "$D/out/$ZNAME" . -x ".git/*" 2>&1 | tail -3
echo "=== 3. verify ==="
ls -lh "$D/out/$ZNAME"
unzip -l "$D/out/$ZNAME" | head -25
echo "=== 4. config proof ==="
grep -E "CONFIG_CPU_FREQ_GOV_GAMING=y|CONFIG_CPU_FREQ_GOV_PERFORMANCE=y|CONFIG_KALLSYMS_ALL=y|CONFIG_LOCALVERSION" "$S/out/.config"
echo "ZIP=$ZNAME"
