#!/system/bin/sh
# DaisyForGaming v1.2 boot tuning
#
# The kernel already ships safe defaults for the important knobs (CPU cap,
# swappiness, boost limits), so this script only refines what userspace owns.
# It must stay conservative: a phone that overheats or kills apps is worse
# than one that scores a few points lower in a benchmark.

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

# Give the ROM performance HAL and the companion app time to finish their
# own boot-time writes, then apply the final values.
sleep 20
say "DaisyForGaming v1.2 tuning start"

# ---------------------------------------------------------------------------
# CPU: stock 2.016 GHz ceiling, no forced minimum, schedutil in charge.
# ---------------------------------------------------------------------------
for c in 0 1 2 3 4 5 6 7; do
  w "/sys/devices/system/cpu/cpu$c/online" 1
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
say "CPU capped at 2016 MHz, floor 652 MHz, schedutil"

# cpu_input_boost is the only boost driver that can reach the top OPP.
# Keep touch response but do not park the CPU at max.
if [ -d /sys/module/cpu_input_boost/parameters ]; then
  w /sys/module/cpu_input_boost/parameters/input_boost_freq 1401600
  w /sys/module/cpu_input_boost/parameters/input_boost_duration 150
  w /sys/module/cpu_input_boost/parameters/wake_boost_duration 300
  w /sys/module/cpu_input_boost/parameters/max_boost_freq 2016000
  say "cpu_input_boost: 1401 MHz / 150 ms, max 2016 MHz"
fi

# The companion app's gaming profile is allowed to raise the input boost
# frequencies, but boosting while charging is a heat trap.
if [ -e /sys/module/cpu_boost/parameters/boost_on_charging ]; then
  w /sys/module/cpu_boost/parameters/boost_on_charging 0
  say "cpu_boost: boost_on_charging = 0"
fi

# ---------------------------------------------------------------------------
# GPU: stock governor and minimum, bus gating enabled again.
# ---------------------------------------------------------------------------
w /sys/class/kgsl/kgsl-3d0/devfreq/governor msm-adreno-tz
w /sys/class/kgsl/kgsl-3d0/min_clock_mhz 216
w /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 216000000
w /sys/class/kgsl/kgsl-3d0/idle_timer 80
w /sys/class/kgsl/kgsl-3d0/force_bus_on 0
say "GPU: msm-adreno-tz, 216 MHz floor, force_bus_on = 0"

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
for q in /sys/block/mmcblk*/queue /sys/block/dm-*/queue; do
  if [ -d "$q" ]; then
    w "$q/read_ahead_kb" 1024
    w "$q/nr_requests" 128
    w "$q/iostats" 0
    [ -f "$q/scheduler" ] && w "$q/scheduler" deadline
  fi
done
say "storage: read_ahead 1024 KB, nr_requests 128, deadline"

# ---------------------------------------------------------------------------
# zram: keep lz4 and make sure the swap device is up.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# VM: use zram for anonymous pages and keep file cache resident.
# ---------------------------------------------------------------------------
# These procfs files are init-owned under SELinux on Android 11, so the
# writes below can be denied even for root.  The v1.2 kernel already ships
# swappiness=100 and page-cluster=0 as compiled defaults; log what is
# actually in effect instead of assuming the write worked.
w /proc/sys/vm/swappiness 100
w /proc/sys/vm/vfs_cache_pressure 100
w /proc/sys/vm/dirty_ratio 20
w /proc/sys/vm/dirty_background_ratio 10
w /proc/sys/vm/dirty_expire_centisecs 200
w /proc/sys/vm/dirty_writeback_centisecs 500
w /proc/sys/vm/page-cluster 0
say "VM: swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null) vfs_cache_pressure=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null) page-cluster=$(cat /proc/sys/vm/page-cluster 2>/dev/null)"

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
w /proc/sys/net/core/default_qdisc fq 2>/dev/null
w /proc/sys/net/ipv4/tcp_congestion_control bbr 2>/dev/null || \
w /proc/sys/net/ipv4/tcp_congestion_control westwood 2>/dev/null || \
w /proc/sys/net/ipv4/tcp_congestion_control cubic 2>/dev/null
say "TCP congestion control configured"

# ---------------------------------------------------------------------------
# Sound.  The GSI ships a charging-sound URI that makes system_server throw
# an IllegalStateException on some charge events; disabling the sound is the
# only userspace-side fix and it stops the SystemUI restart loop.
# ---------------------------------------------------------------------------
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

say "gov: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
say "min: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null) max: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)"
say "DaisyForGaming v1.2 boot tuning completed"
