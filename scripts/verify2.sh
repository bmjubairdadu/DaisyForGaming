#!/bin/bash
S=/root/daisy-build/kernel_source
C=$S/out/.config
echo '--- LZ4 crypto ---'
grep -n 'config CRYPTO_LZ4' $S/crypto/Kconfig | head -3
grep -E 'CRYPTO_LZ4|CRYPTO_LZO|CRYPTO_ZSTD' $C | head -5
echo '--- BLKCGROUP ---'
grep -E 'BLK_CGROUP=' $C | head -2
echo '--- SCHEDTUNE ---'
grep -n -A3 'config CGROUP_SCHEDTUNE' $S/init/Kconfig | head -8
echo '--- DT default iosched current ---'
grep -E 'DEFAULT_IOSCHED|DEFAULT_CFQ|IOSCHED_CFQ|IOSCHED_NOOP' $C | head -6
echo 'VERIFY2_DONE'
