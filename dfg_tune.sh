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

sleep 20
say "DaisyForGaming v1.4 tuning start"

for c in 0 1 2 3 4 5 6 7; do
  w "/sys/devices/system/cpu/cpu$c/online" 1
done

for ctl in /sys/devices/system/cpu/cpu*/core_ctl; do
  if [ -d "$ctl" ]; then
    w "$ctl/min_cpus" 4
  fi
done

for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq \
         /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
  w "$f" 2016000
done
for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_min_freq \
         /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do
  w "$f" 652800
done
for g in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor \
         /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  w "$g" schedutil
done

for s in /sys/devices/system/cpu/cpufreq/policy*/schedutil \
         /sys/devices/system/cpu/cpu*/cpufreq/schedutil \
         /sys/devices/system/cpu/cpufreq/schedutil; do
  if [ -d "$s" ]; then
    w "$s/up_rate_limit_us" 500
    w "$s/down_rate_limit_us" 3000
  fi
done
say "CPU capped at 2016 MHz, floor 652 MHz, schedutil rate limits configured"

if [ -e /sys/module/cpu_boost/parameters/boost_mode ]; then
  w /sys/module/cpu_boost/parameters/boost_mode 2
  w /sys/module/cpu_boost/parameters/sched_boost_on_input 0
  w /sys/module/cpu_boost/parameters/input_boost_ms 80
  say "cpu_boost: boost_mode = 2 (gaming), sched_boost_on_input = 0, input_boost_ms = 80"
fi

if [ -d /sys/module/cpu_input_boost/parameters ]; then
  w /sys/module/cpu_input_boost/parameters/input_boost_freq 1401600
  w /sys/module/cpu_input_boost/parameters/input_boost_duration 80
  w /sys/module/cpu_input_boost/parameters/wake_boost_duration 150
  w /sys/module/cpu_input_boost/parameters/max_boost_freq 2016000
  say "cpu_input_boost: 1401 MHz / 80 ms, max 2016 MHz"
fi

if [ -e /sys/module/cpu_boost/parameters/boost_on_charging ]; then
  w /sys/module/cpu_boost/parameters/boost_on_charging 0
  say "cpu_boost: boost_on_charging = 0"
fi

w /sys/class/kgsl/kgsl-3d0/devfreq/governor msm-adreno-tz
w /sys/class/kgsl/kgsl-3d0/min_clock_mhz 216
w /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 216000000
w /sys/class/kgsl/kgsl-3d0/idle_timer 80
w /sys/class/kgsl/kgsl-3d0/force_bus_on 1
say "GPU: msm-adreno-tz, 216 MHz floor, force_bus_on = 1"

if [ -e /dev/stune/top-app/schedtune.boost ]; then
  w /dev/stune/top-app/schedtune.boost 20
  w /dev/stune/top-app/schedtune.prefer_idle 1
fi
if [ -e /dev/stune/foreground/schedtune.boost ]; then
  w /dev/stune/foreground/schedtune.boost 5
  w /dev/stune/foreground/schedtune.prefer_idle 1
fi
w /proc/sys/kernel/sched_walt_rotate_big_tasks 1 2>/dev/null

for cg in /dev/cpuset; do
  if [ -d "$cg" ]; then
    [ -d "$cg/top-app" ] && w "$cg/top-app/cpus" 0-7
    [ -d "$cg/foreground" ] && w "$cg/foreground/cpus" 0-7
    [ -d "$cg/background" ] && w "$cg/background/cpus" 0-3
    [ -d "$cg/system-background" ] && w "$cg/system-background/cpus" 0-7
    [ -d "$cg/restricted" ] && w "$cg/restricted/cpus" 0-3
  fi
done
say "CPUSets and Schedtune optimized"

for irq in $(grep -iE "goodix|focaltech|ft5x06|synaptics|fts" /proc/interrupts 2>/dev/null | awk '{print $1}' | tr -d ':'); do
  w "/proc/irq/$irq/smp_affinity_list" "0-3"
done

for q in /sys/block/mmcblk*/queue /sys/block/dm-*/queue; do
  if [ -d "$q" ]; then
    w "$q/read_ahead_kb" 256
    w "$q/nr_requests" 128
    w "$q/iostats" 0
    [ -f "$q/scheduler" ] && w "$q/scheduler" deadline
  fi
done
say "storage: read_ahead 256 KB, nr_requests 128, deadline"

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

w /proc/sys/vm/swappiness 60
w /proc/sys/vm/vfs_cache_pressure 60
w /proc/sys/vm/dirty_ratio 20
w /proc/sys/vm/dirty_background_ratio 5
w /proc/sys/vm/dirty_expire_centisecs 200
w /proc/sys/vm/dirty_writeback_centisecs 500
w /proc/sys/vm/page-cluster 0
say "VM: swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null) vfs_cache_pressure=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null) page-cluster=$(cat /proc/sys/vm/page-cluster 2>/dev/null)"

w /proc/sys/net/core/rmem_max 8388608
w /proc/sys/net/core/wmem_max 8388608
w /proc/sys/net/core/rmem_default 1048576
w /proc/sys/net/core/wmem_default 1048576
w /proc/sys/net/ipv4/tcp_rmem "4096 87380 8388608"
w /proc/sys/net/ipv4/tcp_wmem "4096 65536 8388608"
w /proc/sys/net/ipv4/tcp_low_latency 1 2>/dev/null
w /proc/sys/net/ipv4/tcp_fastopen 3 2>/dev/null
w /proc/sys/net/ipv4/tcp_autocorking 0 2>/dev/null
w /proc/sys/net/ipv4/tcp_notsent_lowat 16384 2>/dev/null
w /proc/sys/net/ipv4/tcp_tw_reuse 1 2>/dev/null
w /proc/sys/net/core/default_qdisc fq 2>/dev/null
w /proc/sys/net/ipv4/tcp_congestion_control westwood 2>/dev/null || \
w /proc/sys/net/ipv4/tcp_congestion_control bbr 2>/dev/null || \
w /proc/sys/net/ipv4/tcp_congestion_control cubic 2>/dev/null
say "Network, low-ping gaming and TCP streaming buffers optimized"

settings put global charging_sounds_enabled 0 2>/dev/null
settings put secure charging_sounds_enabled 0 2>/dev/null
settings put global wireless_charging_sounds_enabled 0 2>/dev/null
say "charging sounds disabled"

if [ -d /sys/kernel/sound_control ]; then
  w /sys/kernel/sound_control/headphone_gain "4 4"
  w /sys/kernel/sound_control/speaker_gain 4
  w /sys/kernel/sound_control/mic_gain 2
  w /sys/kernel/sound_control/earpiece_gain 3
  say "sound_control boost applied"
fi

if [ -d /sys/kernel/dyn_fsync ]; then
  w /sys/kernel/dyn_fsync/Dyn_fsync_active 1
  say "dynamic fsync enabled"
fi

for wl in /sys/class/wakeup/*; do
  if [ -f "$wl/name" ]; then
    read -r wl_name < "$wl/name"
    case "$wl_name" in
      *wlan_pno*|*wlan_ipa*|*qcom_rx_wakelock*|*IPA_WS*|*wlan_wow_wl*|*wlan_extscan_wl*)
        [ -f "$wl/device/power/wakeup" ] && w "$wl/device/power/wakeup" disabled
        ;;
    esac
  fi
done
say "wakelock blocker and wakeup suppression applied"

say "gov: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
say "min: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null) max: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)"
say "DaisyForGaming v1.4 boot tuning completed"
