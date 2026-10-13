#!/system/bin/sh

LOG=/data/local/tmp/dfg_tune.log
say() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }
w() { echo "$2" > "$1" 2>/dev/null; }

if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 102400 ]; then
  : > "$LOG"
fi

i=0
while [ $i -lt 120 ]; do
  [ "$(getprop sys.boot_completed)" = "1" ] && break
  i=$((i+1)); sleep 1
done
say "v1.0-final tuning start"

# Load DFG kernel modules (CRC-exact build). vermagic mismatch = skipped.
if [ -d /data/adb/dfg_modules ]; then
  for ko in /data/adb/dfg_modules/*.ko; do
    [ -e "$ko" ] || continue
    modname=$(basename "$ko" | sed 's/_.*//')
    if ! grep -q "$modname" /proc/modules 2>/dev/null; then
      insmod "$ko" 2>/dev/null \
        && say "module loaded: $(basename $ko)" \
        || say "module load skipped (vermagic mismatch): $(basename $ko)"
    fi
  done
fi

if [ -e /sys/module/cpu_boost/parameters/boost_mode ]; then
  w /sys/module/cpu_boost/parameters/boost_mode 3 \
    && say "boost_mode = 3 (auto: game detect via GPU busy >= 50%, screen-aware)"
  w /sys/module/cpu_boost/parameters/boost_on_charging 0 \
    && say "boost_on_charging = 0 (no boost while plugged in)"
elif [ -e /sys/module/cpu_boost/parameters/input_boost_freq ]; then
  echo "0:1036800 1:1036800 2:1036800 3:1036800 4:1401600 5:1401600 6:1401600 7:1401600" \
    > /sys/module/cpu_boost/parameters/input_boost_freq 2>/dev/null \
    && say "input_boost_freq = 1036(little)/1401(big) MHz (legacy path)"
  w /sys/module/cpu_boost/parameters/input_boost_ms 150 && say "input_boost_ms = 150"
  w /sys/module/cpu_boost/parameters/sched_boost_on_input 0 && say "sched_boost_on_input = 0 (cooler)"
  w /sys/module/cpu_boost/parameters/boost_on_charging 0 \
    && say "boost_on_charging = 0 (charging-aware boost: no boost while plugged in)"
else
  say "cpu_boost not present"
fi

if [ -e /sys/kernel/mm/uksm/cpu_governor ]; then
  w /sys/kernel/mm/uksm/cpu_governor low && say "uksm governor = low"
fi


if [ -e /dev/stune/top-app/schedtune.boost ]; then
  w /dev/stune/top-app/schedtune.boost 10 && say "top-app schedtune.boost = 10"
  w /dev/stune/top-app/schedtune.prefer_idle 1 && say "top-app schedtune.prefer_idle = 1"
else
  say "no /dev/stune/top-app"
fi

if [ -b /dev/block/zram0 ]; then
  ALG=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null | tr '\n' ' ')
  case "$ALG" in
    *"[lz4]"*) say "comp_algorithm = lz4 (already)" ;;
    *) echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null \
        || echo 1 > /sys/block/zram0/comp_algorithm 2>/dev/null \
        && say "comp_algorithm = lz4 (set)" ;;
  esac
  n=0
  while [ $n -lt 12 ]; do
    if grep -q "zram0" /proc/swaps 2>/dev/null; then
      say "zram swap ON (attempt $((n+1)))"
      break
    fi
    mkswap /dev/block/zram0 >/dev/null 2>&1
    swapon /dev/block/zram0 >/dev/null 2>&1
    n=$((n+1))
    [ $n -lt 12 ] && sleep 10
  done
  if grep -q "zram0" /proc/swaps 2>/dev/null; then
    say "SwapTotal: $(grep SwapTotal /proc/meminfo 2>/dev/null)"
  else
    say "zram swap still OFF after retries (check ROM zram init)"
  fi
else
  say "no zram0 device"
fi

w /proc/sys/vm/page-cluster 0 && say "page-cluster = 0"
w /proc/sys/vm/vfs_cache_pressure 50 && say "vfs_cache_pressure = 50"
w /proc/sys/vm/swappiness 30 && say "swappiness = 30 (WROTE OK)" || say "swappiness write FAILED"

say "gov: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
say "cpu7 max: $(cat /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq 2>/dev/null)"
say "boost_mode now = $(cat /sys/module/cpu_boost/parameters/boost_mode 2>/dev/null) (effective: $(cat /sys/module/cpu_boost/parameters/boost_mode_effective 2>/dev/null))"
say "auto_gpu_busy now = $(cat /sys/module/cpu_boost/parameters/auto_gpu_busy 2>/dev/null)"
say "bypass_on_gaming = $(cat /sys/module/cpu_boost/parameters/bypass_on_gaming 2>/dev/null)"
say "battery_charging_enabled = $(cat /sys/class/power_supply/battery/battery_charging_enabled 2>/dev/null)"
say "charging_enabled = $(cat /sys/class/power_supply/battery/charging_enabled 2>/dev/null)"
say "schedutil up/down rate limit: $(cat /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us 2>/dev/null)/$(cat /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us 2>/dev/null)"
say "swappiness now = $(cat /proc/sys/vm/swappiness 2>/dev/null)"
say "fsync_enabled = $(cat /sys/module/sync/parameters/fsync_enabled 2>/dev/null)"
say "v1.0-final tuning done"
