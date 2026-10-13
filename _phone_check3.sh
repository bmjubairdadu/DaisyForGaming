#!/system/bin/sh
echo "=== who is 'aat' ==="
ps -A | grep -i aat
echo "=== full panic log: first Oops/panic lines ==="
grep -n -E 'Unable to handle|Kernel panic|BUG:|Oops|memacc|Internal error|pc :' /sys/fs/pstore/console-ramoops-0 | head -40
echo "=== head of log (first oops) ==="
head -60 /sys/fs/pstore/console-ramoops-0
