#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===== P1. powersuspend present? ====="
ls $S/kernel/power/powersuspend.c 2>/dev/null && echo HAS_POWERSUSPEND || echo NO_POWERSUSPEND
grep -rn "POWERSUSPEND" $S/kernel/power/Kconfig 2>/dev/null | head -3
grep -E "POWERSUSPEND" $S/out/.config | head -3
echo ""
echo "===== P2. dynamic fsync present? ====="
grep -rln "dyn.*fsync\|DYNAMIC_FSYNC" $S/fs/ $S/kernel/ 2>/dev/null | head -5
grep -E "FSYNC" $S/out/.config | head -5
echo "(empty = no dynfsync, would need new sysfs - doable)"
echo ""
echo "===== P3. crc check toggle present? ====="
grep -rn "crc-check\|BYPASS_CRC\|F2FS.*CRC" $S/fs/f2fs/Kconfig 2>/dev/null | head -5
echo ""
echo "===== P4. arch_power / sched boost knobs ====="
grep -rn "SCHED_BOOST" $S/kernel/sched/Kconfig $S/init/Kconfig 2>/dev/null | head -5
echo ""
echo "===== P5. msm_performance touchboost? ====="
grep -rn "msm_performance\|touchboost" $S/drivers/soc/qcom/Kconfig 2>/dev/null | head -5
ls $S/drivers/soc/qcom/ | grep -iE "perf|boost" | head -5
