#!/bin/bash
cd /mnt/d/DaisyForGaming
echo "=== deca-cpu-max-step zone full ==="
sed -n '/deca-cpu-max-step/,/^};/p' arch/arm64/boot/dts/qcom/msm8953-thermal.dtsi | head -55
