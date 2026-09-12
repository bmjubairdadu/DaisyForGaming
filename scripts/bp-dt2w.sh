#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===== D1. DT2W: does focaltech panel support gesture mode? ====="
grep -rn "FTS_GESTURE_EN" $S/drivers/input/touchscreen/focaltech_touch/focaltech_config.h $S/drivers/input/touchscreen/focaltech_touch/*.h 2>/dev/null | head -5
grep -rn "gesture" $S/drivers/input/touchscreen/focaltech_touch/focaltech_gesture.c | head -8
echo ""
echo "===== D2. which panel does daisy use? ====="
grep -rn "focaltech\|gt917\|ft5x06\|synaptics" $S/arch/arm64/boot/dts/qcom/daisy/*.dtsi 2>/dev/null | head -8
echo ""
echo "===== D3. input boost: adjustable knobs? ====="
grep -n "module_param\|DEVICE_ATTR\|sysfs" $S/drivers/cpufreq/cpu_input_boost.c | head -10
grep -E "INPUT_BOOST" $S/out/.config
