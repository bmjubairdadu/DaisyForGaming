#!/bin/bash
# Deep research: what gaming features REALLY exist in TogoFire 4.9.337 daisy tree
SRC=/root/daisy-build/kernel_source
OUT=/root/daisy-build/research.txt
{
echo "===== 1. CPU GOVERNORS (files) ====="
ls "$SRC/drivers/cpufreq/" | grep -iE "gov|sched|boost|hotplug|alucard|elemental|darkness|zzmoove|blu_|smartmax|intelli|yank| impulse|ironactive" || echo "(no custom governors by name)"
echo ""
echo "===== 2. cpufreq Kconfig options ====="
grep -rE "^config CPU_FREQ_GOV_" "$SRC/drivers/cpufreq/" | sed 's/:.*config/: config/'
echo ""
echo "===== 3. schedutil present? ====="
grep -rl "schedutil" "$SRC/drivers/cpufreq/" "$SRC/kernel/sched/" 2>/dev/null | head
grep -rn "SCHEDUTIL" "$SRC/drivers/cpufreq/Kconfig" "$SRC/drivers/cpufreq/Makefile" 2>/dev/null | head
echo ""
echo "===== 4. interactive governor present? ====="
find "$SRC" -iname "*interactive*" -not -path "*/.git/*" | head
echo ""
echo "===== 5. cpu-boost / input-boost ====="
ls "$SRC/drivers/cpufreq/" | grep -i boost
grep -n "CPU_BOOST\|INPUT_BOOST\|SCHED_BOOST\|SCHEDTUNE" "$SRC/drivers/cpufreq/Kconfig" 2>/dev/null | head
grep -rn "SCHEDTUNE" "$SRC/init/Kconfig" 2>/dev/null | head -5
echo ""
echo "===== 6. IO SCHEDULERS ====="
ls "$SRC/block/" | head -n 40
grep -rE "^config (IOSCHED|MQ_IOSCHED|BFQ|CFQ|DEADLINE|NOOP|ROW|ZEN|TRIPNDROID|SIO|FIOPS|MAPLE)" "$SRC/block/Kconfig" "$SRC/block/Kconfig.iosched" 2>/dev/null | head -n 30
echo ""
echo "===== 7. TCP CONGESTION ====="
ls "$SRC/net/ipv4/" | grep -iE "cong|bbr|cubic|westwood|illinois|htcp|vegas|cdg" | head -n 20
grep -rE "^config (TCP_CONG_BBR|TCP_CONG_CUBIC|TCP_CONG_WESTWOOD)" "$SRC/net/ipv4/Kconfig" 2>/dev/null | head
echo ""
echo "===== 8. GPU (msm/adreno/kgsl) OC support ====="
ls "$SRC/drivers/gpu/drm/msm/" 2>/dev/null | head -n 20
find "$SRC" -path "*arm64/boot/dts*" -iname "*daisy*" -o -path "*arm64/boot/dts*" -iname "*msm8953*" 2>/dev/null | head
echo ""
echo "===== 9. KCAL / DT2W / FastCharge / SoundControl / Wakelock ====="
grep -rli "kcal" "$SRC/drivers/" 2>/dev/null | head -5
grep -rli "sweep2wake\|doubletap2wake\|wakeup_gestures" "$SRC/drivers/input/" 2>/dev/null | head -5
grep -rli "fast_charge\|force_fast_charge" "$SRC/drivers/power/" "$SRC/drivers/usb/" 2>/dev/null | head -5
grep -rli "sound_control\|soundcontrol\|fauxsound\|boeffla_sound" "$SRC/" --include=Kconfig 2>/dev/null | head -5
grep -rli "wakelock_blocker\|boeffla_wakelock" "$SRC/" --include="*.c" 2>/dev/null | head -5
echo ""
echo "===== 10. DTS CPU/GPU freq tables (msm8953 daisy) ====="
DTS=$(find "$SRC/arch/arm64/boot/dts" -iname "*daisy*" | head -1)
echo "daisy dts: $DTS"
grep -n "qcom,speed-bin\|operating-points\|opp-" $DTS 2>/dev/null | head -10
echo ""
echo "===== 11. Current .config key gaming values ====="
CFG="$SRC/out/.config"
for k in CONFIG_CPU_FREQ_GOV_SCHEDUTIL CONFIG_CPU_FREQ_GOV_INTERACTIVE CONFIG_CPU_BOOST CONFIG_SCHEDTUNE CONFIG_TCP_CONG_BBR CONFIG_TCP_CONG_ADVANCED CONFIG_IOSCHED_BFQ CONFIG_IOSCHED_CFQ CONFIG_DEFAULT_CFQ CONFIG_ZRAM CONFIG_ZSMALLOC CONFIG_DEBUG_FS CONFIG_ANDROID_BINDER_IPC CONFIG_F2FS_FS CONFIG_DM_VERITY CONFIG_OVERLAY_FS CONFIG_CGROUP_SCHEDTUNE; do
  v=$(grep -E "^$k=|^# $k is not set" "$CFG" 2>/dev/null || echo "$k=NOT-IN-CONFIG")
  echo "$v"
done
echo ""
echo "===== 12. defconfig stock gaming-relevant lines ====="
BASE="$SRC/arch/arm64/configs/daisy_defconfig"
for k in CONFIG_CPU_FREQ_GOV_SCHEDUTIL CONFIG_CPU_FREQ_GOV_INTERACTIVE CONFIG_CPU_BOOST CONFIG_TCP_CONG_BBR CONFIG_ZRAM CONFIG_DEBUG_FS; do
  v=$(grep -E "^$k=|^# $k is not set" "$BASE" 2>/dev/null || echo "$k=NOT-IN-DEFCONFIG")
  echo "$v"
done
} | tee "$OUT"
echo "RESEARCH_SAVED: $OUT"
