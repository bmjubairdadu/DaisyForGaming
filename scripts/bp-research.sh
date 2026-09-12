#!/bin/bash
# Phase 1: research for backports - kernel version APIs + existing hooks
S=/root/daisy-build/kernel_source
echo '--- G1. cpufreq governor API (4.9 style) ---'
grep -n 'struct cpufreq_governor' $S/include/linux/cpufreq.h | head -5
grep -n 'GOVERNOR_START\|GOVERNOR_STOP\|GOVERNOR_LIMITS' $S/include/linux/cpufreq.h | head -8
echo '--- G2. schedutil impl reference ---'
ls $S/kernel/sched/cpufreq_schedutil.c $S/kernel/sched/cpufreq_governor.c $S/kernel/sched/cpufreq_governor.h 2>/dev/null
grep -n 'GOVERNOR_START\|GOVERNOR_STOP\|GOVERNOR_LIMITS\|GOVERNOR_POLICY_INIT\|GOVERNOR_POLICY_EXIT' $S/drivers/cpufreq/cpufreq_ondemand.c | head -10
echo '--- G3. devfreq boost API ---'
grep -n 'DEVFREQ_BOOST\|devfreq_boost' $S/drivers/devfreq/devfreq_boost.c | head -10
grep -n 'config DEVFREQ_BOOST\|config DEVFREQ_INPUT_BOOST' $S/drivers/devfreq/Kconfig | head -5
grep -E 'DEVFREQ_BOOST|DEVFREQ_INPUT_BOOST' $S/out/.config
echo '--- G4. touchscreen gesture configs ---'
grep -rn 'TOUCHSCREEN_FT5X06_GESTURE\|TOUCHSCREEN_FTS_GESTURE' $S/drivers/input/touchscreen/*/Kconfig $S/drivers/input/touchscreen/Kconfig 2>/dev/null | head -8
echo '--- G5. qpnp charger current tunable ---'
grep -n 'ibatmax\|fastchg.*current\|charge.*current' $S/drivers/power/supply/qcom/qpnp-smbcharger.c | head -8
echo '--- G6. boeffla/existing sound hooks ---'
grep -rn 'wcd9335\|tasha\|headphone.*gain\|speaker.*gain' $S/sound/soc/codecs/wcd9335.c 2>/dev/null | head -5
ls $S/sound/soc/codecs/ | head -20
echo BACKPORT_RESEARCH_DONE
