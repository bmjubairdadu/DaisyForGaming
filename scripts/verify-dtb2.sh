#!/bin/bash
S=/root/daisy-build/kernel_source
echo '--- Q1. exact image sizes (bytes) ---'
stat -c '%n %s bytes' $S/out/arch/arm64/boot/Image.gz $S/out/arch/arm64/boot/Image.gz-dtb $S/out/arch/arm64/boot/Image 2>/dev/null
echo '--- Q2. all DTC lines in build.log ---'
grep -c 'DTC' $S/../../daisy-build/out/build.log 2>/dev/null || grep -c 'DTC' /root/daisy-build/out/build.log
grep 'DTC' /root/daisy-build/out/build.log | head -20
echo '--- Q3. dtb makefile ---'
grep -n 'daisy\|sakura\|dtb-y' $S/arch/arm64/boot/dts/qcom/Makefile | head -20
echo '--- Q4. DTB_OBJS / appended names ---'
grep -rn 'DTB_OBJS' $S/arch/arm64/boot/Makefile | head -5
grep -E 'APPENDED' $S/out/.config
echo DTB_Q_DONE
