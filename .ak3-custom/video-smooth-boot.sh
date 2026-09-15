#!/system/bin/sh
# DaisyForGaming v2.2 VIDEO-SMOOTH boot tweaks (runs via AnyKernel3 exec).
# All writes are guarded: missing nodes are skipped, failures ignored.
# - TCP CUBIC default for steady video streaming (kernel kconfig choice
#   cannot be flipped in this 4.9 tree; BBR stays available at runtime).
# - VM readahead 1MB window for 1080p streaming (kernel default raised too).

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

exit 0
