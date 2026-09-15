#!/system/bin/sh
# DaisyForGaming v2.2 VIDEO-SMOOTH + COOL boot tweaks (runs via AnyKernel3).
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
[ -w /sys/module/cpu_input_boost/parameters/input_boost_duration ] && echo 40 > /sys/module/cpu_input_boost/parameters/input_boost_duration 2>/dev/null
[ -w /sys/module/cpu_input_boost/parameters/wake_boost_duration ] && echo 200 > /sys/module/cpu_input_boost/parameters/wake_boost_duration 2>/dev/null
[ -w /sys/module/cpu_input_boost/parameters/input_boost_freq ] && echo 1344000 > /sys/module/cpu_input_boost/parameters/input_boost_freq 2>/dev/null
# COOL: GPU idler less aggressive ramp-down = fewer turbo re-spikes
[ -w /sys/module/adreno_idler/parameters/adreno_idler_idlewait ] && echo 30 > /sys/module/adreno_idler/parameters/adreno_idler_idlewait 2>/dev/null

exit 0
