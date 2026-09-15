#!/system/bin/sh
# DaisyForGaming v1.2 STABLE boot tweaks (runs via AnyKernel3).
# v1.2 balance: schedutil up 2ms (was 0.5ms - caused heat/flicker),
# boost holds 80/400ms, swappiness 60, KSM 1000ms. All guarded.
# All writes are guarded: missing nodes are skipped, failures ignored.
# - TCP CUBIC default for steady video streaming (kernel kconfig choice
#   cannot be flipped in this 4.9 tree; BBR stays available at runtime).
# - VM readahead 1MB window for 1080p streaming (kernel default raised too).
# - COOL (no perf loss): shorter input-boost hold (less heat soak) + GPU
#   idle hysteresis (fewer turbo spikes). Burst perf unchanged: fastramp
#   up=0.5ms still jumps instantly; only the HOLD time is trimmed.

# TCP congestion: prefer cubic, fallback westwood, keep BBR available
if [ -w /proc/sys/net/ipv4/tcp_congestion_control ]; then
	if grep -q cubic /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
		echo cubic > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null
	fi
fi

# Readahead: 2048 sectors (1MB) for smooth streaming refill
for q in /sys/block/mmcblk0/queue/read_ahead_kb; do
	[ -w "$q" ] && echo 1024 > "$q" 2>/dev/null
done

# COOL: trim boost hold times (burst jump stays instant via fastramp)
[ -w /sys/module/cpu_input_boost/parameters/input_boost_duration ] && echo 80 > /sys/module/cpu_input_boost/parameters/input_boost_duration 2>/dev/null
[ -w /sys/module/cpu_input_boost/parameters/wake_boost_duration ] && echo 400 > /sys/module/cpu_input_boost/parameters/wake_boost_duration 2>/dev/null
[ -w /sys/module/cpu_input_boost/parameters/input_boost_freq ] && echo 1344000 > /sys/module/cpu_input_boost/parameters/input_boost_freq 2>/dev/null
# COOL: GPU idler less aggressive ramp-down = fewer turbo re-spikes
[ -w /sys/module/adreno_idler/parameters/adreno_idler_idlewait ] && echo 20 > /sys/module/adreno_idler/parameters/adreno_idler_idlewait 2>/dev/null

# RAM PRESSURE (3GB daisy): keep memory reclaim healthy under high load.
# swappiness 100 = swap anonymous pages to ZRAM early instead of dropping
# file caches (video/game assets stay cached -> fewer reload stutters).
# vfs_cache_pressure 50 = keep dentries/inodes longer (faster app open).
# dirty ratios low = writeback in small chunks, no big I/O freeze.
[ -w /proc/sys/vm/swappiness ] && echo 60 > /proc/sys/vm/swappiness 2>/dev/null
[ -w /proc/sys/vm/vfs_cache_pressure ] && echo 80 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null
[ -w /proc/sys/vm/dirty_ratio ] && echo 20 > /proc/sys/vm/dirty_ratio 2>/dev/null
[ -w /proc/sys/vm/dirty_background_ratio ] && echo 10 > /proc/sys/vm/dirty_background_ratio 2>/dev/null
# KSM: dedup identical pages across apps (browser/game share libs).
[ -w /sys/kernel/mm/ksm/run ] && echo 1 > /sys/kernel/mm/ksm/run 2>/dev/null
[ -w /sys/kernel/mm/ksm/sleep_millisecs ] && echo 1000 > /sys/kernel/mm/ksm/sleep_millisecs 2>/dev/null

exit 0
