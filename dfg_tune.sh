#!/system/bin/sh
# DaisyForGaming System Boot Tuning & Autonomous Free Fire Bypass Charging Service
# Author: JUBAIR HOSEN

LOG=/data/local/tmp/dfg_tune.log
PIDFILE=/data/local/tmp/dfg_ff_monitor.pid

say() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }
w() { echo "$2" > "$1" 2>/dev/null; }

# Rotate log if too big
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 102400 ]; then
  : > "$LOG"
fi

# Wait for boot completion (up to 120s)
i=0
while [ $i -lt 120 ]; do
  [ "$(getprop sys.boot_completed)" = "1" ] && break
  i=$((i+1)); sleep 1
done

say "DaisyForGaming autonomous tuning start"

# 1. CPU Boost Profile & Touch Boost
if [ -e /sys/module/cpu_boost/parameters/boost_mode ]; then
  w /sys/module/cpu_boost/parameters/boost_mode 1 \
    && say "boost_mode = 1 (Balanced default)"
  w /sys/module/cpu_boost/parameters/boost_on_charging 1 \
    && say "boost_on_charging = 1 (touch responsive while charging)"
fi

if [ -e /sys/module/cpu_boost/parameters/input_boost_freq ]; then
  echo "0:1036800 1:1036800 2:1036800 3:1036800 4:1401600 5:1401600 6:1401600 7:1401600" \
    > /sys/module/cpu_boost/parameters/input_boost_freq 2>/dev/null \
    && say "input_boost_freq = 1036(little)/1401(big) MHz"
  w /sys/module/cpu_boost/parameters/input_boost_ms 60 && say "input_boost_ms = 60"
  w /sys/module/cpu_boost/parameters/sched_boost_on_input 1 && say "sched_boost_on_input = 1"
fi

# 2. Schedutil governor responsiveness & 60fps frame holding (Prevents video/UI stutter)
for cpu_sched in /sys/devices/system/cpu/cpu*/cpufreq/schedutil; do
  if [ -d "$cpu_sched" ]; then
    w "$cpu_sched/up_rate_limit_us" 500
    w "$cpu_sched/down_rate_limit_us" 20000
  fi
done
say "schedutil rate limits configured (up: 500us, down: 20000us for 60fps pacing)"

# 3. Top-app & Foreground schedtune & CPUSets responsiveness (Zero video/UI jitter)
if [ -e /dev/stune/top-app/schedtune.boost ]; then
  w /dev/stune/top-app/schedtune.boost 10 && say "top-app schedtune.boost = 10"
  w /dev/stune/top-app/schedtune.prefer_idle 1 && say "top-app schedtune.prefer_idle = 1"
fi
if [ -e /dev/stune/foreground/schedtune.boost ]; then
  w /dev/stune/foreground/schedtune.boost 5 && say "foreground schedtune.boost = 5"
  w /dev/stune/foreground/schedtune.prefer_idle 1 && say "foreground schedtune.prefer_idle = 1"
fi
for cg in /dev/cpuset; do
  [ -d "$cg/top-app" ] && w "$cg/top-app/cpus" 0-7
  [ -d "$cg/foreground" ] && w "$cg/foreground/cpus" 0-7
  [ -d "$cg/background" ] && w "$cg/background/cpus" 0-3
  [ -d "$cg/system-background" ] && w "$cg/system-background/cpus" 0-3
done
say "CPUSets optimized (top-app & foreground assigned all 8 cores)"

# 4. GPU & Display Anti-Lag (Butter smooth 60fps / 1080p / 2K / 4K video & gaming)
w /sys/module/adreno_idler/parameters/adreno_idler_active 0
w /sys/class/kgsl/kgsl-3d0/devfreq/adreno_idler_active 0
w /sys/class/kgsl/kgsl-3d0/devfreq/governor msm-adreno-tz
w /sys/class/kgsl/kgsl-3d0/min_clock_mhz 216
w /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 216000000
w /sys/class/kgsl/kgsl-3d0/idle_timer 80
say "GPU governor = msm-adreno-tz (min_clock: 216MHz for 60fps video compositing)"

# 5. Storage I/O Read-Ahead Optimization (Smooth 1080p/2K/4K high-bitrate video playback)
for q in /sys/block/mmcblk*/queue /sys/block/dm-*/queue; do
  if [ -d "$q" ]; then
    w "$q/read_ahead_kb" 1024
    w "$q/iostats" 0
  fi
done
say "Storage read_ahead_kb = 1024 (optimized for HD/4K playback)"

# 6. Disable UKSM/KSM completely (Eliminates background page scanning, CPU heating & video lag)
w /sys/kernel/mm/uksm/run 0
w /sys/kernel/mm/ksm/run 0
say "uksm/ksm = 0 (disabled to eliminate background CPU load & heating)"

# 7. Force Fast Charge out of the box (2000mA = 2.0A fast charging)
if [ -e /sys/kernel/fast_charge/force_fast_charge ]; then
  w /sys/kernel/fast_charge/fast_charge_current 2000
  w /sys/kernel/fast_charge/force_fast_charge 1
  say "force_fast_charge = 1 (2000mA target)"
fi

# 8. zRAM & VM Tuning (Butter smooth multitasking, zero memory stalls, no screen freezes)
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

w /proc/sys/vm/vfs_cache_pressure 100 && say "vfs_cache_pressure = 100 (balanced dentry/inode cache)"
w /proc/sys/vm/swappiness 60 && say "swappiness = 60"
w /proc/sys/vm/dirty_ratio 20 && say "dirty_ratio = 20 (smooth buffering, no I/O stalls)"
w /proc/sys/vm/dirty_background_ratio 10 && say "dirty_background_ratio = 10"
w /proc/sys/vm/dirty_expire_centisecs 200
w /proc/sys/vm/dirty_writeback_centisecs 500
w /proc/sys/vm/min_free_kbytes 32768 && say "min_free_kbytes = 32768 (smooth reclaim headroom)"
w /proc/sys/vm/extra_free_kbytes 24576 && say "extra_free_kbytes = 24576"
w /proc/sys/vm/watermark_scale_factor 200 && say "watermark_scale_factor = 200"
w /proc/sys/vm/page-cluster 0 && say "page-cluster = 0"

say "gov: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
say "DaisyForGaming boot tuning completed successfully"

# ==============================================================================
# Autonomous RAM & Application Junk Cleaner Daemon
# Screen-Aware: NEVER touches memory while screen is ON (zero freezes / zero video lag).
# Cleans filesystem junk and maintains RAM health silently when phone is asleep.
# ==============================================================================
RAM_CLEAN_PIDFILE=/data/local/tmp/dfg_ram_cleaner.pid
if [ -f "$RAM_CLEAN_PIDFILE" ]; then
  OLD_PID=$(cat "$RAM_CLEAN_PIDFILE" 2>/dev/null)
  [ -n "$OLD_PID" ] && [ -d "/proc/$OLD_PID" ] && kill -9 "$OLD_PID" 2>/dev/null
fi

is_screen_on() {
  # 1. Backlight brightness
  bl=$(cat /sys/class/leds/lcd-backlight/brightness 2>/dev/null)
  [ -n "$bl" ] && [ "$bl" -gt 0 ] && return 0

  # 2. Framebuffer blank status (0 = ON / UNBLANK)
  fb=$(cat /sys/class/graphics/fb0/blank 2>/dev/null)
  [ "$fb" = "0" ] && return 0

  # 3. DRM CRTC active
  crtc=$(cat /sys/class/drm/card0/sde-crtc-0/active 2>/dev/null)
  [ "$crtc" = "1" ] && return 0

  return 1
}

(
  echo $$ > "$RAM_CLEAN_PIDFILE"
  say "Autonomous Screen-Aware RAM & Junk Cleaner active (PID: $$)"

  while true; do
    sleep 45

    # Ensure UKSM/KSM remains disabled
    [ -e /sys/kernel/mm/uksm/run ] && echo 0 > /sys/kernel/mm/uksm/run 2>/dev/null
    [ -e /sys/kernel/mm/ksm/run ] && echo 0 > /sys/kernel/mm/ksm/run 2>/dev/null

    # If user is actively using the phone (screen ON): DO NOT TOUCH MEMORY!
    if is_screen_on; then
      continue
    fi

    # User is NOT using phone (screen OFF / locked). Confirm screen stays off for 15s:
    sleep 15
    if is_screen_on; then
      continue
    fi

    # Clean storage junk files silently
    rm -rf /data/tombstones/* /data/system/dropbox/* /data/anr/* 2>/dev/null
    rm -rf /data/local/tmp/kflash /data/local/tmp/ak3 /data/local/tmp/test 2>/dev/null
    rm -f /data/local/tmp/*.log.bak 2>/dev/null

    # Check free memory while screen is OFF
    avail=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null)
    if [ -n "$avail" ] && [ "$avail" -lt 307200 ]; then
      # Free dentries/inodes safely without evicting active app code
      echo 2 > /proc/sys/vm/drop_caches 2>/dev/null
      echo 1 > /proc/sys/vm/compact_memory 2>/dev/null
      say "Screen-off maintenance: dentries trimmed & memory compacted (MemAvailable was ${avail}KB)"
    fi
  done
) &

# ==============================================================================
# Autonomous Free Fire Targeted Bypass Charging & Gaming Boost Daemon
# Targets: com.dts.freefiremax and com.dts.freefireth
# When running & plugged in: Bypass charging ON (Direct adapter power, 0 battery charge)
# When unplugged or game closed: Normal charging & balanced profile restored.
# ==============================================================================

is_charger_connected() {
  [ "$(cat /sys/class/power_supply/usb/present 2>/dev/null)" = "1" ] && return 0
  [ "$(cat /sys/class/power_supply/usb/online 2>/dev/null)" = "1" ] && return 0
  case "$(cat /sys/class/power_supply/battery/status 2>/dev/null)" in
    "Charging"|"Full"|"Not charging") return 0 ;;
  esac
  return 1
}

is_ff_active() {
  # Direct cgroup & proc scan (<0.5ms, zero overhead, never blocks system_server)
  for cg in /dev/cpuset/top-app/cgroup.procs /dev/stune/top-app/cgroup.procs; do
    if [ -f "$cg" ]; then
      for pid in $(cat "$cg" 2>/dev/null); do
        cmd=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null)
        case "$cmd" in
          *com.dts.freefiremax*|*com.dts.freefireth*) return 0 ;;
        esac
      done
    fi
  done

  # Fallback: fast pidof (checks /proc directly without starting JVM)
  if pidof com.dts.freefiremax com.dts.freefireth >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

enable_bypass() {
  w /sys/kernel/fast_charge/bypass_charging 1
  w /sys/class/power_supply/battery/battery_charging_enabled 0
  w /sys/class/power_supply/battery/charging_enabled 0
  w /sys/module/cpu_boost/parameters/boost_mode 2
  w /dev/stune/top-app/schedtune.boost 15
}

disable_bypass() {
  w /sys/kernel/fast_charge/bypass_charging 0
  w /sys/class/power_supply/battery/battery_charging_enabled 1
  w /sys/class/power_supply/battery/charging_enabled 1
  w /sys/module/cpu_boost/parameters/boost_mode 1
  w /dev/stune/top-app/schedtune.boost 10
}

# Kill previous monitor instance if running
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
  if [ -n "$OLD_PID" ] && [ -d "/proc/$OLD_PID" ]; then
    kill -9 "$OLD_PID" 2>/dev/null
  fi
fi

# Launch background monitor daemon
(
  echo $$ > "$PIDFILE"
  say "Free Fire targeted bypass monitor daemon started (PID: $$)"
  prev_state="init"

  while true; do
    sleep 2
    if is_charger_connected && is_ff_active; then
      if [ "$prev_state" != "bypass" ]; then
        enable_bypass
        prev_state="bypass"
        say "Free Fire detected + charger plugged -> BYPASS CHARGING ACTIVE (Phone runs off AC adapter)"
      fi
    else
      if [ "$prev_state" != "normal" ]; then
        disable_bypass
        prev_state="normal"
        say "Free Fire inactive or charger unplugged -> Normal mode restored"
      fi
    fi
  done
) &
