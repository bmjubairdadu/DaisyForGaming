#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===== C1. msm8x16 codec file ====="
ls $S/sound/soc/codecs/ | grep -iE "8x16|pmic|analog"
echo ""
echo "===== C2. RX digital gain controls ====="
grep -n "RX.*Volume\|Digital Volume\|HPHL Volume\|Speaker.*Volume" $S/sound/soc/codecs/msm8x16_wcd.c 2>/dev/null | head -10
grep -rn "SOC_SINGLE.*Volume" $S/sound/soc/codecs/msm8x16_wcd.c 2>/dev/null | head -5
echo ""
echo "===== C3. wakelock blocker: find any existing block list? ====="
grep -rln "wakelock.*block\|BLOCKED_WAKELOCK\|block_wakelock" $S --include="*.c" --include="*.h" 2>/dev/null | grep -v ".git" | head -5
echo "(empty = none, will add minimal sysfs filter)"
echo ""
echo "===== C4. frozen: powersuspend hooks for DT2W ====="
grep -n "register_powersuspend\|POWERSUSPEND" $S/drivers/input/touchscreen/focaltech_touch/focaltech_core.c 2>/dev/null | head -5
grep -n "powersuspend" $S/include/linux/powersuspend.h 2>/dev/null | head -8
ls $S/include/linux/powersuspend.h 2>/dev/null || echo NO_POWERSUSPEND_H
