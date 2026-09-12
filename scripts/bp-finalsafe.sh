#!/bin/bash
S=/root/daisy-build/kernel_source
echo "==Q1 BFQ code exists?=="
grep -n "IOSCHED_BFQ\|BFQ_GROUP" "$S/block/Kconfig" "$S/block/Kconfig.iosched" 2>/dev/null | head -10
ls "$S/block/" | cat
echo ""
echo "==Q2 adreno tz in base?=="
grep -n "ADRENO_TZ\|ADRENO_IDLER\|QCOM_ADRENO" "$S/arch/arm64/configs/daisy_defconfig"
grep -n "ADRENO_TZ\|ADRENO_IDLER" "$S/drivers/devfreq/Kconfig" | head -8
echo ""
echo "==Q3 kcal already?=="
grep -n "KCAL" "$S/arch/arm64/configs/daisy_defconfig"
echo ""
echo "==Q4 TCP BBR lines=="
grep -n "TCP_CONG" "$S/arch/arm64/configs/daisy_defconfig"
echo ""
echo "==Q5 schedutil already default?=="
grep -n "DEFAULT_GOV\|SCHEDUTIL" "$S/arch/arm64/configs/daisy_defconfig" | head -8
