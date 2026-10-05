#!/system/bin/sh
# DaisyForGaming v1.0 - runtime tuning (runs from Magisk service.d each boot).
# Re-asserts the input-boost values the kernel already boots with, lifts the
# top-app schedtune group, enables zram lz4 swap (with retry: the ROM's init
# configures zram concurrently around 40-50s, so one early swapon can race
# it), applies vm sysctls, and logs the final state for diagnostics.

LOG=/data/local/tmp/dfg_tune.log
say() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }
w() { echo "$2" > "$1" 2>/dev/null; }

i=0
while [ $i -lt 120 ]; do
  [ "$(getprop sys.boot_completed)" = "1" ] && break
  i=$((i+1)); sleep 1
done
say "v1.0 tuning start"

# ---- CPU input boost (re-assert kernel defaults) ----
if [ -e /sys/module/cpu_boost/parameters/input_boost_freq ]; then
  echo "0:1401600 1:1401600 2:1401600 3:1401600 4:1689600 5:1689600 6:1689600 7:1689600" \
    > /sys/module/cpu_boost/parameters/input_boost_freq 2>/dev/null \
    && say "input_boost_freq = 1401(little)/1689(big) MHz"
  w /sys/module/cpu_boost/parameters/input_boost_ms 300 && say "input_boost_ms = 300"
  w /sys/module/cpu_boost/parameters/sched_boost_on_input 1 && say "sched_boost_on_input = 1"
else
  say "cpu_boost not present"
fi

# ---- top-app schedtune group: foreground stays preferred ----
if [ -e /dev/stune/top-app/schedtune.boost ]; then
  w /dev/stune/top-app/schedtune.boost 10 && say "top-app schedtune.boost = 10"
  w /dev/stune/top-app/schedtune.prefer_idle 1 && say "top-app schedtune.prefer_idle = 1"
else
  say "no /dev/stune/top-app"
fi

# ---- zram swap (lz4; retry while ROM init races us) ----
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

# ---- vm tuning ----
w /proc/sys/vm/page-cluster 0 && say "page-cluster = 0"
w /proc/sys/vm/vfs_cache_pressure 20 && say "vfs_cache_pressure = 20"
w /proc/sys/vm/swappiness 30 && say "swappiness = 30 (WROTE OK)" || say "swappiness write FAILED"
w /proc/sys/vm/dirty_background_ratio 5 && say "dirty_background_ratio = 5"

# ---- final state for diagnostics ----
say "gov: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
say "cpu7 max: $(cat /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq 2>/dev/null)"
say "swappiness now = $(cat /proc/sys/vm/swappiness 2>/dev/null)"
say "fsync_enabled = $(cat /sys/module/sync/parameters/fsync_enabled 2>/dev/null)"
say "v1.0 tuning done"
