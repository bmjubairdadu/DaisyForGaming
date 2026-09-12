#!/bin/bash
S=/root/daisy-build/kernel_source
C=$S/out/.config
B=$S/arch/arm64/configs/daisy_defconfig
echo '--- V1. FB_MSM_MDSS value (.config + defconfig) ---'
grep -E 'FB_MSM_MDSS=|FB_MSM_MDSS is not set' $C
grep -E 'FB_MSM_MDSS=|FB_MSM_MDSS is not set' $B
echo '--- V2. BFQ Kconfig block ---'
grep -n -A8 'config IOSCHED_BFQ' $S/block/Kconfig.iosched
echo '--- V3. CPU_BOOST Kconfig block ---'
grep -n -A6 'config CPU_BOOST' $S/drivers/cpufreq/Kconfig
echo '--- V4. HZ_300 choice location ---'
grep -rn 'HZ_300' $S/arch/arm64/Kconfig $S/arch/arm/Kconfig $S/kernel/Kconfig.hz 2>/dev/null
ls $S/kernel/Kconfig.hz 2>/dev/null
echo '--- V5. BBR Kconfig block ---'
grep -n -B1 -A5 'config TCP_CONG_BBR' $S/net/ipv4/Kconfig
echo '--- V6. current HZ + TCP defaults in .config ---'
grep -E 'CONFIG_HZ=|CONFIG_HZ_250|CONFIG_HZ_300|DEFAULT_TCP_CONG|DEFAULT_BBR|DEFAULT_WESTWOOD|TCP_CONG_BBR' $C
echo '--- V7. current BFQ/BOOST/KCAL in .config ---'
grep -E 'IOSCHED_BFQ|CPU_BOOST|KCAL' $C
echo '--- VERIFY_DONE ---'
