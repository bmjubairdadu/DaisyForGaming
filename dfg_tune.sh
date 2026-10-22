#!/system/bin/sh
# DaisyForGaming System Boot Tuning
# Device: Xiaomi Mi A2 Lite (daisy) - MSM8953
# Clean, Cool, & Anti-Lag Optimization (No background loops)

LOG=/data/local/tmp/dfg_tune.log
say() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }
w() { echo "$2" > "$1" 2>/dev/null; }

# Rotate log if too big (> 100KB)
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 102400 ]; then
  : > "$LOG"
fi

# Clean up legacy daemon pid files and kill if still lingering
for pidf in /data/local/tmp/dfg_ff_monitor.pid /data/local/tmp/dfg_ram_cleaner.pid; do
  if [ -f "$pidf" ]; then
    old_pid=$(cat "$pidf" 2>/dev/null)
    [ -n "$old_pid" ] && [ -d "/proc/$old_pid" ] && kill -9 "$old_pid" 2>/dev/null
    rm -f "$pidf" 2>/dev/null
  fi
done

# Wait for Android boot completion (up to 120s)
i=0
while [ $i -lt 120 ]; do
  [ "$(getprop sys.boot_completed)" = "1" ] && break
  i=$((i+1)); sleep 1
done

say "DaisyForGaming autonomous tuning start"

# 1. CPU Boost Profile & Touch Boost (Balanced & Cool)
if [ -e /sys/module/cpu_boost/parameters/boost_mode ]; then
  w /sys/module/cpu_boost/parameters/boost_mode 1 \
    && say "boost_mode = 1 (Balanced)"
  # Disable touch boost while charging to prevent device overheating on charger
  w /sys/module/cpu_boost/parameters/boost_on_charging 0 \
    && say "boost_on_charging = 0 (cool charging: no CPU boost while plugged in)"
fi

if [ -e /sys/module/cpu_boost/parameters/input_boost_freq ]; then
  echo "0:1036800 1:1036800 2:1036800 3:1036800 4:1401600 5:1401600 6:1401600 7:1401600" \
    > /sys/module/cpu_boost/parameters/input_boost_freq 2>/dev/null \
    && say "input_boost_freq = 1036(little)/1401(big) MHz"
  w /sys/module/cpu_boost/parameters/input_boost_ms 40 && say "input_boost_ms = 40"
  w /sys/module/cpu_boost/parameters/sched_boost_on_input 0 && say "sched_boost_on_input = 0 (cool & smooth)"
fi

# 2. Schedutil Governor (Instant 1ms ramp, smooth 20ms pacing, allow full idle down to cool clocks)
for cpu_sched in /sys/devices/system/cpu/cpu*/cpufreq/schedutil; do
  if [ -d "$cpu_sched" ]; then
    w "$cpu_sched/up_rate_limit_us" 1000
    w "$cpu_sched/down_rate_limit_us" 20000
  fi
done
say "schedutil rate limits configured (up: 1000us, down: 20000us)"

# 3. Top-app & Foreground Schedtune & CPUSets
if [ -e /dev/stune/top-app/schedtune.boost ]; then
  w /dev/stune/top-app/schedtune.boost 5 && say "top-app schedtune.boost = 5 (responsive game task placement)"
  w /dev/stune/top-app/schedtune.prefer_idle 1 && say "top-app schedtune.prefer_idle = 1"
fi
if [ -e /dev/stune/foreground/schedtune.boost ]; then
  w /dev/stune/foreground/schedtune.boost 0 && say "foreground schedtune.boost = 0"
  w /dev/stune/foreground/schedtune.prefer_idle 1 && say "foreground schedtune.prefer_idle = 1"
fi

for cg in /dev/cpuset; do
  [ -d "$cg/top-app" ] && w "$cg/top-app/cpus" 0-7
  [ -d "$cg/foreground" ] && w "$cg/foreground/cpus" 0-7
  [ -d "$cg/background" ] && w "$cg/background/cpus" 0-3
  [ -d "$cg/system-background" ] && w "$cg/system-background/cpus" 0-3
  [ -d "$cg/restricted" ] && w "$cg/restricted/cpus" 0-3
done
say "CPUSets optimized (top-app & foreground: 0-7, background: 0-3)"

# 4. GPU Scaling (Native Qualcomm msm-adreno-tz, dynamic 133-650MHz)
w /sys/class/kgsl/kgsl-3d0/devfreq/governor msm-adreno-tz
w /sys/module/adreno_idler/parameters/adreno_idler_active 0
w /sys/class/kgsl/kgsl-3d0/devfreq/adreno_idler_active 0
say "GPU governor = msm-adreno-tz (adreno_idler off: butter smooth 60fps in games)"

# 5. Storage I/O Read-Ahead (Smooth 1080p/4K video playback without dropping frames)
for q in /sys/block/mmcblk*/queue /sys/block/dm-*/queue; do
  if [ -d "$q" ]; then
    w "$q/read_ahead_kb" 512
    w "$q/iostats" 0
  fi
done
say "Storage read_ahead_kb = 512 (smooth video buffering)"

# 6. Disable UKSM/KSM (Eliminates background CPU scanning, stops overheating)
w /sys/kernel/mm/uksm/run 0
w /sys/kernel/mm/ksm/run 0
say "uksm/ksm = 0 (disabled to eliminate background CPU load)"

# 7. zRAM & VM Tuning (Smooth multitasking, zero cache dropping, zero video stutter)
if [ -b /dev/block/zram0 ]; then
  ALG=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null | tr '\n' ' ')
  case "$ALG" in
    *"[lz4]"*) say "comp_algorithm = lz4 (already active)" ;;
    *) echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null \
        || echo 1 > /sys/block/zram0/comp_algorithm 2>/dev/null \
        && say "comp_algorithm = lz4 (applied)" ;;
  esac
  n=0
  while [ $n -lt 6 ]; do
    if grep -q "zram0" /proc/swaps 2>/dev/null; then
      say "zram swap active"
      break
    fi
    mkswap /dev/block/zram0 >/dev/null 2>&1
    swapon /dev/block/zram0 >/dev/null 2>&1
    n=$((n+1))
    [ $n -lt 6 ] && sleep 5
  done
fi

w /proc/sys/vm/vfs_cache_pressure 100 && say "vfs_cache_pressure = 100"
w /proc/sys/vm/swappiness 60 && say "swappiness = 60"
w /proc/sys/vm/dirty_ratio 20 && say "dirty_ratio = 20"
w /proc/sys/vm/dirty_background_ratio 10 && say "dirty_background_ratio = 10"
w /proc/sys/vm/dirty_expire_centisecs 200
w /proc/sys/vm/dirty_writeback_centisecs 500
w /proc/sys/vm/min_free_kbytes 8192 && say "min_free_kbytes = 8192"
w /proc/sys/vm/extra_free_kbytes 0 && say "extra_free_kbytes = 0"
w /proc/sys/vm/watermark_scale_factor 10 && say "watermark_scale_factor = 10"
w /proc/sys/vm/page-cluster 0 && say "page-cluster = 0"

# 8. Network TCP Tuning (Smooth streaming for YouTube/Facebook/Browsing)
w /proc/sys/net/ipv4/tcp_congestion_control westwood 2>/dev/null || w /proc/sys/net/ipv4/tcp_congestion_control cubic
say "TCP congestion control configured"

say "gov: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
say "DaisyForGaming boot tuning completed successfully (clean one-shot execution)"
