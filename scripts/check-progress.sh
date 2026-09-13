#!/bin/bash
echo "===DATE==="
date
echo "===OUTDIR==="
ls -lh /mnt/d/Kernel/out/ 2>&1
echo "===KIMAGE==="
ls -lh /mnt/d/Kernel/kernel_source/out/arch/arm64/boot/Image.gz-dtb 2>&1
echo "===BUILDLOG_TAIL==="
tail -n 30 /mnt/d/Kernel/out/build.log 2>&1
echo "===MAKE_PROC==="
ps aux | grep -E "make|gcc|cc1|as|ld" | grep -v grep | head -n 20
echo "===CONFIG_CHECK==="
grep -E "KALLSYMS_BASE_RELATIVE|CONFIG_LD_BFD|CONFIG_LD_LLD|CONFIG_LD_DEAD_CODE|CONFIG_LOCALVERSION" /mnt/d/Kernel/kernel_source/out/.config 2>&1 | head -n 20
