#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===== S1. audio codec on daisy? ====="
grep -rn "wcd93\|wcd93\|tasha\|tavil\|codec" $S/arch/arm64/boot/dts/qcom/msm8953-audio.dtsi 2>/dev/null | head -8
ls $S/sound/soc/codecs/ | grep -iE "msm8x16|wcd93|pm8953|tasha"
echo ""
echo "===== S2. msm8x16-wcd codec gain knobs? ====="
grep -n "RX.*Digital.*Volume\|HPHL.*Volume\|gain" $S/sound/soc/codecs/msm8x16-wcd.c 2>/dev/null | head -8
echo ""
echo "===== F1. smbcharger: max current tables? ====="
grep -n "usb_ilim_ma_table\|dc_ilim_ma_table\|fastchg_current" $S/drivers/power/supply/qcom/qpnp-smbcharger.c | head -12
echo ""
echo "===== F2. thermal: msm8953 trips (safe headroom?) ====="
grep -n -A3 "trips" $S/arch/arm64/boot/dts/qcom/msm8953-thermal.dtsi | head -30
