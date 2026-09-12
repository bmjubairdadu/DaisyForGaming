#!/bin/bash
S=/root/daisy-build/kernel_source
echo '--- DTB1. Image.gz-dtb rule ---'
grep -n -B2 -A6 'Image.gz-dtb' $S/arch/arm64/boot/Makefile | head -40
echo '--- DTB2. APPENDED config in .config ---'
grep -E 'APPENDED' $S/out/.config | head -10
echo '--- DTB3. daisy dtb exists? ---'
ls -lh $S/out/arch/arm64/boot/dts/qcom/ | head -30
echo '--- DTB4. what is inside current Image.gz-dtb? ---'
ls -lh $S/out/arch/arm64/boot/Image.gz-dtb $S/out/arch/arm64/boot/Image.gz 2>/dev/null
echo '--- DTB5. dtb sizes ---'
ls -lh $S/out/arch/arm64/boot/dts/qcom/msm8953-qrd-sku3-daisy.dtb $S/out/arch/arm64/boot/dts/qcom/msm8953-qrd-sku3-sakura.dtb 2>/dev/null
echo DTB_VERIFY_DONE
