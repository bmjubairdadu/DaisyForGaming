#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===== W1. wakelock files ====="
ls $S/kernel/power/ | head -20
grep -rn "wake_lock_init\|wake_lock_destroy" $S/kernel/power/*.c 2>/dev/null | head -5
echo ""
echo "===== W2. wlan wakelock names (daisy uses prima wlan)? ====="
grep -rn "wlan.*wake\|wake.*wlan" $S/drivers/staging/prima/CORE/HDD/src/*.c 2>/dev/null | head -5
echo ""
echo "===== W3. qcom rpm wakelocks? ====="
grep -rln "wake_lock" $S/drivers/soc/qcom/ 2>/dev/null | head -5
echo ""
echo "===== W4. simplest hook point: print name on acquire ====="
grep -n "wake_lock_init\|wake_lock_active\|wake_lock\|wakeup_source_add" $S/kernel/power/wakelock.c 2>/dev/null | head -10
ls $S/kernel/power/wakelock.c $S/kernel/power/wakeup_reason.c 2>/dev/null
