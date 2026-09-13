# DaisyForGaming post-boot tweaks (runs on every boot)
# Matches v2.3 kernel features ONLY - every path verified in 4.9.337 tree.
# By JUBAIR HOSEN. Safe: all lines use 2>/dev/null so missing nodes never fail boot.

# Wait for boot complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
sleep 5

# === CPU: schedutil gaming tuning (default governor) ===
echo schedutil > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
echo schedutil > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor 2>/dev/null
echo 500 > /sys/devices/system/cpu/cpufreq/schedutil/up_rate_limit_us 2>/dev/null
echo 20000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null
echo 1 > /sys/devices/system/cpu/cpufreq/schedutil/iowait_boost_enabled 2>/dev/null
# TIP: switch to gaming governor for max FPS:
# echo gaming > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# echo gaming > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor

# === CPU input boost (kdrag0n driver, stock 1401600 kHz / 100ms) ===
# Tunables (only if driver exposes them):
# echo 1401600 > /sys/module/cpu_input_boost/parameters/input_boost_freq 2>/dev/null
# echo 100 > /sys/module/cpu_input_boost/parameters/input_boost_duration 2>/dev/null

# === GPU: msm-adreno-tz + adreno-idler (stock 650MHz, NO OC) ===
echo msm-adreno-tz > /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null
echo Y > /sys/module/adreno_idler/parameters/adreno_idler_active 2>/dev/null

# === I/O: keep stock CFQ default (video-smooth). BFQ only on demand: ===
# BFQ forces deep queue reordering that stalls video decode on msm8953.
# Keep CFQ (stock, low jitter). Switch manually only for benchmarks:
# echo bfq > /sys/block/mmcblk0/queue/scheduler 2>/dev/null
echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb 2>/dev/null
echo 1 > /sys/block/mmcblk0/queue/iostats 2>/dev/null
echo 1 > /sys/block/mmcblk0/queue/add_random 2>/dev/null

# === Memory (video-smooth: keep swap + background writeback stock-ish) ===
echo 60 > /proc/sys/vm/swappiness 2>/dev/null
echo 20 > /proc/sys/vm/dirty_ratio 2>/dev/null
echo 10 > /proc/sys/vm/dirty_background_ratio 2>/dev/null

# === Network: keep stock westwood (video-stable). BBR only on demand: ===
# BBR's aggressive pacing + tcp_low_latency cause rebuffering on weak links.
# echo bbr > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null
echo 0 > /proc/sys/net/ipv4/tcp_low_latency 2>/dev/null

# === Fsync stays ON (data safety). Toggle only if you accept data-loss risk:
# echo N > /sys/module/sync/parameters/fsync_enabled 2>/dev/null

# === DT2W: enable via Focaltech gesture sysfs (Kernel Adiutor/EXKM):
# echo 1 > fts_gesture_mode node under /sys/devices/soc/.../i2c-.../ 2>/dev/null

# === Wakelock filter (default OFF = stock). Example to block one source:
# echo "wlan_rx" > /sys/module/wakelock/parameters/wakelock_block 2>/dev/null

# === KCAL vivid ===
echo "256 256 256" > /sys/devices/platform/kcal_ctrl.0/kcal 2>/dev/null
echo 255 > /sys/devices/platform/kcal_ctrl.0/kcal_sat 2>/dev/null

# Log
echo "[DaisyForGaming v2.3] Tweaks applied $(date)" > /dev/kmsg 2>/dev/null
