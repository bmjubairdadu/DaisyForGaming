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

# 1. CPU Boost Profile & Touch Boost (Balanced, Cool & Responsive)
if [ -e /sys/module/cpu_boost/parameters/boost_mode ]; then
  w /sys/module/cpu_boost/parameters/boost_mode 1 \
    && say "boost_mode = 1 (Balanced)"
  # Enable touch boost while charging so touch latency doesn't lag while playing plugged in
  w /sys/module/cpu_boost/parameters/boost_on_charging 1 \
    && say "boost_on_charging = 1 (touch responsive while plugged in)"
fi

if [ -e /sys/module/cpu_boost/parameters/input_boost_freq ]; then
  # Boost only cluster lead cores (CPU0 little, CPU4 big) to avoid heating all 8 cores on every touch
  echo "0:1036800 1:0 2:0 3:0 4:1036800 5:0 6:0 7:0" \
    > /sys/module/cpu_boost/parameters/input_boost_freq 2>/dev/null \
    && say "input_boost_freq = 0:1036 4:1036 MHz (cool touch response)"
  w /sys/module/cpu_boost/parameters/input_boost_ms 30 && say "input_boost_ms = 30"
  w /sys/module/cpu_boost/parameters/sched_boost_on_input 0 && say "sched_boost_on_input = 0 (cool & smooth)"
fi

# 2. Schedutil Governor (1ms responsive ramp, quick 4ms cooldown for sustained 60fps & low thermals)
for cpu_sched in /sys/devices/system/cpu/cpu*/cpufreq/schedutil \
                 /sys/devices/system/cpu/cpufreq/policy*/schedutil \
                 /sys/devices/system/cpu/cpufreq/schedutil; do
  if [ -d "$cpu_sched" ]; then
    w "$cpu_sched/up_rate_limit_us" 1000
    w "$cpu_sched/down_rate_limit_us" 4000
  fi
done
say "schedutil rate limits configured (up: 1000us, down: 4000us - cool & fast)"

# 3. Top-app & Foreground Schedtune & CPUSets
if [ -e /dev/stune/top-app/schedtune.boost ]; then
  w /dev/stune/top-app/schedtune.boost 1 && say "top-app schedtune.boost = 1 (balanced frame delivery)"
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
w /sys/class/kgsl/kgsl-3d0/min_clock_mhz 133
w /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 133300000
w /sys/class/kgsl/kgsl-3d0/idle_timer 64
say "GPU governor = msm-adreno-tz (dynamic 133-650MHz, cool idle, instant 60fps ramp)"

# 5. Storage I/O Read-Ahead & Scheduler (Smooth video buffering & fast game scene loading)
for q in /sys/block/mmcblk*/queue /sys/block/dm-*/queue; do
  if [ -d "$q" ]; then
    w "$q/read_ahead_kb" 512
    w "$q/iostats" 0
    [ -f "$q/scheduler" ] && w "$q/scheduler" deadline
  fi
done
say "Storage read_ahead_kb = 512 & deadline scheduler applied"

# 6. Disable UKSM/KSM (Eliminates background CPU scanning, stops overheating)
w /sys/kernel/mm/uksm/run 0
w /sys/kernel/mm/ksm/run 0
say "uksm/ksm = 0 (disabled to eliminate background CPU load)"

# 7. Fast Charging (1500mA cool sweet spot for Snapdragon 625 / PMI8952)
if [ -e /sys/kernel/fast_charge/force_fast_charge ]; then
  w /sys/kernel/fast_charge/force_fast_charge 1
  w /sys/kernel/fast_charge/fast_charge_current 1500
  say "force_fast_charge = 1 (1500mA cool charge current)"
fi

# 8. zRAM & VM Tuning (Smooth multitasking, asynchronous kswapd reclaim, zero frame drops)
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
w /proc/sys/vm/min_free_kbytes 16384 && say "min_free_kbytes = 16384 (eliminates direct reclaim frame drops)"
w /proc/sys/vm/extra_free_kbytes 16384 && say "extra_free_kbytes = 16384"
w /proc/sys/vm/watermark_scale_factor 150 && say "watermark_scale_factor = 150"
w /proc/sys/vm/page-cluster 0 && say "page-cluster = 0"

# 9. Network TCP Tuning (Low-latency BBR/FQ for online gaming & video streaming)
w /proc/sys/net/core/default_qdisc fq 2>/dev/null
w /proc/sys/net/ipv4/tcp_congestion_control bbr 2>/dev/null || \
w /proc/sys/net/ipv4/tcp_congestion_control westwood 2>/dev/null || \
w /proc/sys/net/ipv4/tcp_congestion_control cubic 2>/dev/null
say "TCP congestion control configured (BBR/FQ low-jitter gaming pacing)"

say "gov: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
say "DaisyForGaming boot tuning completed successfully (clean one-shot execution)"
