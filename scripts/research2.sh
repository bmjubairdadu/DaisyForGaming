#!/bin/bash
SRC=/root/daisy-build/kernel_source
CFG=$SRC/out/.config
BASE=$SRC/arch/arm64/configs/daisy_defconfig
{
echo "===== A. All GOV related .config ====="
grep -E "CPU_FREQ_GOV|CPU_FREQ_DEFAULT_GOV|CPUFREQ_DT" "$CFG" | head -n 20
echo ""
echo "===== B. GOV defaults in defconfig ====="
grep -E "CPU_FREQ|GOV" "$BASE" | head -n 20
echo ""
echo "===== C. PERFORMANCE governor Kconfig? ====="
grep -rn "GOV_PERFORMANCE\|GOV_ONDEMAND\|DEFAULT_GOV" "$SRC/drivers/cpufreq/Kconfig" | head -n 20
echo ""
echo "===== D. CPU_BOOST defaults ====="
sed -n '175,250p' "$SRC/drivers/cpufreq/Kconfig" 2>/dev/null || grep -n -A5 "CPU_BOOST\|INPUT_BOOST" "$SRC/drivers/cpufreq/Kconfig.arm" | head -n 60
echo ""
echo "===== E. BFQ Kconfig help ====="
grep -n -B2 -A8 "config IOSCHED_BFQ" "$SRC/block/Kconfig.iosched" | head -n 30
echo ""
echo "===== F. TCP default ====="
grep -E "TCP_CONG|DEFAULT_TCP" "$CFG" | head
grep -n -A3 "DEFAULT_TCP_CONG\|TCP_CONG_CUBIC" "$SRC/net/ipv4/Kconfig" | head -n 20
echo ""
echo "===== G. GPU freq table (adreno/kgsl DTS) ====="
grep -rn "gpu.*opp\|operating-points\|qcom,gpu-freq\|kgsl" "$SRC/arch/arm64/boot/dts/qcom/msm8953-gpu.dtsi" 2>/dev/null | head -n 20
ls "$SRC/arch/arm64/boot/dts/qcom/" | grep -iE "gpu|8953" | head -n 20
echo ""
echo "===== H. CPU max freq (dts + qcom-cpufreq) ====="
grep -rn "clock-frequency\|opp-" "$SRC/arch/arm64/boot/dts/qcom/msm8953-cpu.dtsi" 2>/dev/null | head -n 20
grep -n "8939\|8953\|max.*freq\|2.*GHz\|2016\|2208" "$SRC/drivers/cpufreq/qcom-cpufreq.c" 2>/dev/null | head -n 20
echo ""
echo "===== I. KCAL real check ====="
grep -rli "mdss_pp.*kcal\|kcal_ctrl\|LCD_KCAL" "$SRC/drivers/" 2>/dev/null | head -5
echo "(empty above = NO KCAL driver)"
echo ""
echo "===== J. FastCharge real check ====="
grep -rli "force_fast_charge\|fastcharge" "$SRC/drivers/power/" "$SRC/drivers/usb/" 2>/dev/null | head -5
echo "(empty above = NO fastcharge driver)"
echo ""
echo "===== K. DT2W real check ====="
grep -rli "doubletap2wake\|sweep2wake\|gesture.*wake" "$SRC/drivers/input/touchscreen/" 2>/dev/null | head -5
echo "(empty above = NO DT2W driver)"
echo ""
echo "===== L. SoundControl real check ====="
grep -rli "sound_control\|faux_sound\|boeffla" "$SRC/sound/" "$SRC/drivers/" 2>/dev/null | grep -vi binary | head -5
echo "(empty above = NO sound mod driver)"
echo ""
echo "===== M. Wakelock blocker real check ====="
grep -rli "wakelock.*block\|block.*wakelock" "$SRC/kernel/" "$SRC/drivers/base/" 2>/dev/null | head -5
echo "(empty above = NO wakelock blocker)"
echo ""
echo "===== N. Thermal zones for 8953 ====="
ls "$SRC/arch/arm64/boot/dts/qcom/" | grep -iE "thermal" | head
grep -rn "thermal-zones\|trips" "$SRC/arch/arm64/boot/dts/qcom/msm8953.dtsi" 2>/dev/null | head -5
echo ""
echo "===== O. Binder/IPC/F2FS/verity in .config ====="
for k in CONFIG_ANDROID_BINDER_IPC CONFIG_ASHMEM CONFIG_F2FS_FS CONFIG_DM_VERITY CONFIG_OVERLAY_FS CONFIG_QUOTA CONFIG_QUOTACTL CONFIG_CGROUP_SCHEDTUNE CONFIG_CPU_FREQ_GOV_ONDEMAND CONFIG_CPU_FREQ_GOV_CONSERVATIVE CONFIG_CPU_FREQ_GOV_POWERSAVE CONFIG_CPU_FREQ_GOV_USERSPACE CONFIG_CPU_BOOST CONFIG_CPU_INPUT_BOOST CONFIG_IOSCHED_BFQ CONFIG_IOSCHED_CFQ CONFIG_DEFAULT_CFQ CONFIG_TCP_CONG_HTCP CONFIG_TCP_CONG_ADVANCED CONFIG_ZRAM CONFIG_ZSMALLOC CONFIG_SWAP; do
  v=$(grep -E "^$k=|^# $k is not set" "$CFG" 2>/dev/null || echo "$k=NOT-IN-CONFIG")
  echo "$v"
done
} | tee /root/daisy-build/research2.txt
echo "RESEARCH2_SAVED"
