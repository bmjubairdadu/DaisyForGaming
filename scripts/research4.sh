#!/bin/bash
SRC=/root/daisy-build/kernel_source
CFG=$SRC/out/.config
{
echo "===== R4-A. KCAL Makefile + Kconfig exact ====="
grep -rn -i "kcal" "$SRC/drivers/video/fbdev/msm/Makefile" | head -5
grep -rn -i "kcal" "$SRC/drivers/video/fbdev/msm/Kconfig" | head -10
echo ""
echo "===== R4-B. adreno-tz governor ====="
ls "$SRC/drivers/devfreq/" | head -n 20
grep -rn "ADRENO_TZ\|MSM_ADRENO_TZ\|QCOM_ADRENOTZ" "$SRC/drivers/devfreq/Kconfig" 2>/dev/null | head -5
grep -E "ADRENO|MSM_ADRENO|DEVFREQ.*TZ" "$CFG" | head -5
echo ""
echo "===== R4-C. MSM thermal / core_ctl symbols ====="
grep -rn "config MSM_THERMAL\|config MSM_CORE_CTL\|config INTELLI_THERMAL" "$SRC/drivers/thermal/" "$SRC/drivers/soc/qcom/" 2>/dev/null | head -5
grep -E "MSM_THERMAL|MSM_CORE_CTL|MSM_PERFORMANCE" "$CFG" | head -5
echo ""
echo "===== R4-D. fastcharge string context ====="
grep -rn -i "fastcharge\|force_fast_charge" "$SRC/drivers/power/supply/qcom/qpnp-smbcharger.c" 2>/dev/null | head -3
grep -rn "config.*FAST_CHARGE\|config.*FORCE_FAST" "$SRC/" --include=Kconfig 2>/dev/null | head -5
echo "(empty=config none => NO fastcharge tunable)"
echo ""
echo "===== R4-E. DT2W gesture config ====="
grep -rn -i "config.*GESTURE\|config.*DT2W\|config.*DOUBLETAP" "$SRC/drivers/input/touchscreen/" 2>/dev/null | head -5
grep -rn -i "gesture" "$SRC/drivers/input/touchscreen/focaltech_touch/focaltech_core.c" 2>/dev/null | head -3
echo ""
echo "===== R4-F. BFQ default choice lines ====="
grep -n -B3 -A10 "choice" "$SRC/block/Kconfig.iosched" | head -n 40
echo ""
echo "===== R4-G. BBR default choice ====="
sed -n '670,710p' "$SRC/net/ipv4/Kconfig" | head -n 45
} | tee /root/daisy-build/research4.txt
echo "RESEARCH4_SAVED"
