#!/bin/bash
S=/root/daisy-build/kernel_source
echo "==B1 devfreq boost symbol=="
grep -n "DEVFREQ_BOOST\|devfreq_boost" "$S/drivers/devfreq/Kconfig" "$S/drivers/devfreq/Makefile" 2>/dev/null | head -8
echo ""
echo "==B2 dyn sync sysfs=="
cat "$S/include/linux/dyn_sync_cntrl.h" 2>/dev/null | head -30
echo ""
echo "==B3 FTS gesture sysfs node=="
grep -n "device_create_file\|sysfs\|gesture_switch\|DEVICE_ATTR" "$S/drivers/input/touchscreen/focaltech_touch/focaltech_gesture.c" 2>/dev/null | head -10
ls "$S/drivers/input/touchscreen/focaltech_touch/" | cat
