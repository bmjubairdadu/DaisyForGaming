#!/system/bin/sh
echo "=== dmesg panic/watchdog/thermal tail ==="
dmesg | grep -iE 'panic|watchdog|reboot|shutdown|thermal|restart|emerg' | tail -40
echo "=== last_kmsg / pstore ==="
ls -la /proc/last_kmsg /sys/fs/pstore/ 2>/dev/null
cat /proc/last_kmsg 2>/dev/null | tail -50
echo "=== boot reason ==="
cat /sys/module/msm_poweroff/parameters/* 2>/dev/null | head -5
getprop ro.boot.bootreason 2>/dev/null
getprop sys.boot.reason 2>/dev/null
echo "=== current uptime ==="
uptime
cat /proc/uptime
