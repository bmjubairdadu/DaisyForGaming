#!/bin/bash
S=/root/daisy-build/kernel_source
echo "==W1 wakelock API=="
grep -n "wake_lock\|wakeup_source\|print_active\|pm_wake" "$S/kernel/power/wakelock.c" 2>/dev/null | head -15
ls "$S/kernel/power/" | head -20
echo ""
echo "==W2 input boost params=="
grep -n "module_param\|boost_ms\|input_boost_freq" "$S/drivers/cpufreq/cpu_input_boost.c" | head -12
echo ""
echo "==W3 dynfsync in sync.c=="
grep -n "dynfsync\|dynamic_fsync\|module_param\|early_suspend\|powersuspend" "$S/fs/sync.c" | head -10
echo ""
echo "==W4 powersuspend header=="
sed -n '1,60p' "$S/include/linux/powersuspend.h"
echo ""
echo "==W5 FTS gesture mode var=="
grep -n "GESTURE\|gesture\|dclick\|DT2W\|wake_gesture" "$S/drivers/input/touchscreen/focaltech_touch/focaltech_core.c" | head -12
grep -rn "FTS_GESTURE_EN" "$S/drivers/input/touchscreen/focaltech_touch/" | head -5
echo ""
echo "==W6 sound wcd location=="
find "$S/sound" -iname "*wcd*" 2>/dev/null | head -5
find "$S" -iname "*msm8x16*" 2>/dev/null | grep -v ".git" | head -5
