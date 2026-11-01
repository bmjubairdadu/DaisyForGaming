#!/system/bin/sh

LOG=/data/local/tmp/dfg_tune.log
say() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }
w() { echo "$2" > "$1" 2>/dev/null; }

if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 102400 ]; then
  : > "$LOG"
fi

for pidf in /data/local/tmp/dfg_ff_monitor.pid /data/local/tmp/dfg_ram_cleaner.pid; do
  if [ -f "$pidf" ]; then
    old_pid=$(cat "$pidf" 2>/dev/null)
    [ -n "$old_pid" ] && [ -d "/proc/$old_pid" ] && kill -9 "$old_pid" 2>/dev/null
    rm -f "$pidf" 2>/dev/null
  fi
done

i=0
while [ $i -lt 120 ]; do
  [ "$(getprop sys.boot_completed)" = "1" ] && break
  i=$((i+1)); sleep 1
done

say "DaisyForGaming autonomous tuning start"

if [ -e /sys/module/cpu_boost/parameters/boost_mode ]; then
  w /sys/module/cpu_boost/parameters/boost_mode 1 && say "boost_mode = 1"
  w /sys/module/cpu_boost/parameters/boost_on_charging 1 && say "boost_on_charging = 1"
fi

if [ -e /sys/module/cpu_boost/parameters/input_boost_freq ]; then
  echo "0:1401600 1:1401600 2:1401600 3:1401600 4:1401600 5:1401600 6:1401600 7:1401600" \
    > /sys/module/cpu_boost/parameters/input_boost_freq 2>/dev/null && say "input_boost_freq = 1401 MHz"
  w /sys/module/cpu_boost/parameters/input_boost_ms 60 && say "input_boost_ms = 60"
  w /sys/module/cpu_boost/parameters/sched_boost_on_input 1 && say "sched_boost_on_input = 1"
fi

for cpu_sched in /sys/devices/system/cpu/cpu*/cpufreq/schedutil \
                 /sys/devices/system/cpu/cpufreq/policy*/schedutil \
                 /sys/devices/system/cpu/cpufreq/schedutil; do
  if [ -d "$cpu_sched" ]; then
    w "$cpu_sched/up_rate_limit_us" 500
    w "$cpu_sched/down_rate_limit_us" 20000
  fi
done
say "schedutil rate limits configured"

if [ -e /dev/stune/top-app/schedtune.boost ]; then
  w /dev/stune/top-app/schedtune.boost 10 && say "top-app schedtune.boost = 10"
  w /dev/stune/top-app/schedtune.prefer_idle 1 && say "top-app schedtune.prefer_idle = 1"
fi
if [ -e /dev/stune/foreground/schedtune.boost ]; then
  w /dev/stune/foreground/schedtune.boost 1 && say "foreground schedtune.boost = 1"
  w /dev/stune/foreground/schedtune.prefer_idle 1 && say "foreground schedtune.prefer_idle = 1"
fi

for cg in /dev/cpuset; do
  [ -d "$cg/top-app" ] && w "$cg/top-app/cpus" 0-7
  [ -d "$cg/foreground" ] && w "$cg/foreground/cpus" 0-7
  [ -d "$cg/background" ] && w "$cg/background/cpus" 0-3
  [ -d "$cg/system-background" ] && w "$cg/system-background/cpus" 0-3
  [ -d "$cg/restricted" ] && w "$cg/restricted/cpus" 0-3
done
say "CPUSets optimized"

w /sys/class/kgsl/kgsl-3d0/devfreq/governor msm-adreno-tz
w /sys/module/adreno_idler/parameters/adreno_idler_active 0
w /sys/class/kgsl/kgsl-3d0/devfreq/adreno_idler_active 0
w /sys/class/kgsl/kgsl-3d0/min_clock_mhz 216
w /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 216000000
w /sys/class/kgsl/kgsl-3d0/idle_timer 80
say "GPU governor = msm-adreno-tz"

for q in /sys/block/mmcblk*/queue /sys/block/dm-*/queue; do
  if [ -d "$q" ]; then
    w "$q/read_ahead_kb" 512
    w "$q/iostats" 0
    [ -f "$q/scheduler" ] && w "$q/scheduler" deadline
  fi
done
say "Storage read_ahead_kb = 512 & deadline scheduler applied"

w /sys/kernel/mm/uksm/run 0
w /sys/kernel/mm/ksm/run 0
say "uksm/ksm = 0"

if [ -e /sys/kernel/fast_charge/force_fast_charge ]; then
  w /sys/kernel/fast_charge/force_fast_charge 1
  w /sys/kernel/fast_charge/fast_charge_current 1500
  say "force_fast_charge = 1 (1500mA)"
fi

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
w /proc/sys/vm/min_free_kbytes 16384 && say "min_free_kbytes = 16384"
w /proc/sys/vm/extra_free_kbytes 16384 && say "extra_free_kbytes = 16384"
w /proc/sys/vm/watermark_scale_factor 150 && say "watermark_scale_factor = 150"
w /proc/sys/vm/page-cluster 0 && say "page-cluster = 0"

w /proc/sys/net/core/default_qdisc fq 2>/dev/null
w /proc/sys/net/ipv4/tcp_congestion_control bbr 2>/dev/null || \
w /proc/sys/net/ipv4/tcp_congestion_control westwood 2>/dev/null || \
w /proc/sys/net/ipv4/tcp_congestion_control cubic 2>/dev/null
say "TCP congestion control configured"

if [ -d /sys/kernel/sound_control ]; then
  w /sys/kernel/sound_control/headphone_gain "4 4"
  w /sys/kernel/sound_control/speaker_gain 4
  w /sys/kernel/sound_control/mic_gain 2
  w /sys/kernel/sound_control/earpiece_gain 3
  say "sound_control boost applied: HP +4dB, SPK +4dB, MIC +2dB, EAR +3dB"
fi

say "gov: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
say "DaisyForGaming boot tuning completed successfully"
