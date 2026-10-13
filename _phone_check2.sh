#!/system/bin/sh
echo "=== pstore console-ramoops-0 : last 120 lines ==="
cat /sys/fs/pstore/console-ramoops-0 2>/dev/null | tail -120
