#!/bin/bash
SRC=/root/daisy-build/kernel_source
CFG=$SRC/out/.config
{
echo "===== R3-A. KCAL exact symbol ====="
grep -rn -B3 -A3 "kcal" "$SRC/drivers/video/fbdev/msm/Kconfig" | head -n 30
echo ""
echo "===== R3-B. PERF/POWERSAVE gov symbols ====="
grep -rn "GOV_PERFORMANCE\|GOV_POWERSAVE" "$SRC/drivers/cpufreq/Kconfig" | head
grep -E "PERFORMANCE|POWERSAVE" "$CFG" | head
echo ""
echo "===== R3-C. NOOP/DEADLINE stock ====="
grep -E "IOSCHED_NOOP|IOSCHED_DEADLINE|DEFAULT_NOOP|DEFAULT_DEADLINE|DEFAULT_CFQ|DEFAULT_BFQ" "$CFG" | head
echo ""
echo "===== R3-D. FQ_CODEL / FQ status ====="
grep -E "NET_SCH_FQ_CODEL|NET_SCH_FQ\b|NET_SCH_FQ=" "$CFG" | head
grep -rn "config NET_SCH_FQ_CODEL" "$SRC/net/sched/Kconfig" | head -3
echo ""
echo "===== R3-E. HZ value ====="
grep -E "^CONFIG_HZ=|CONFIG_HZ_" "$CFG" | head
echo ""
echo "===== R3-F. DEVFREQ governors ====="
grep -E "DEVFREQ|ADRENOTZ|MSM_ADRENO_TZ|GOV_PERFORMANCE|GOV_POWERSAVE|GOV_USERSPACE|GOV_PASSIVE" "$CFG" | head -n 15
echo ""
echo "===== R3-G. WALT / ENERGY_AWARE ====="
grep -E "SCHED_WALT|WALT|ENERGY_AWARE|SCHEDTUNE" "$CFG" | head
grep -rn "config SCHED_WALT" "$SRC/" --include=Kconfig 2>/dev/null | head -3
echo ""
echo "===== R3-H. MSM core_ctl / thermal gov ====="
grep -E "MSM_CORE_CTL|MSM_THERMAL|THERMAL_DEFAULT|INTELLI_THERMAL" "$CFG" | head
echo ""
echo "===== R3-I. DEFAULT TCP CONG ====="
grep -E "DEFAULT_TCP_CONG|DEFAULT_CUBIC|DEFAULT_BBR|DEFAULT_WESTWOOD" "$CFG" | head
grep -n -B2 -A6 'config DEFAULT_BBR' "$SRC/net/ipv4/Kconfig" | head -n 20
echo ""
echo "===== R3-J. ION /ASHMEM stock ====="
grep -E "^CONFIG_ION=|^CONFIG_ASHMEM=" "$CFG" | head
echo ""
echo "===== R3-K. INPUT_BOOST values ====="
grep -E "INPUT_BOOST|BASE_BOOST|MAX_BOOST|WAKE_BOOST" "$CFG" | head
} | tee /root/daisy-build/research3.txt
echo "RESEARCH3_SAVED"
