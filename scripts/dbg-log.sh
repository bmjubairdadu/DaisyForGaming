#!/bin/bash
echo "LOGCHECK"
ls -la /tmp/ 2>&1 | head -20
echo "---nohup---"
ls -la ~/ 2>&1 | grep -i nohup
echo "---ps---"
ps aux 2>&1 | grep -E "rebuild|make|gcc" | grep -v grep | head -8 || echo NOMAKE
echo "---Image date---"
ls -lh /root/daisy-build/kernel_source/out/arch/arm64/boot/Image.gz-dtb 2>&1
date
