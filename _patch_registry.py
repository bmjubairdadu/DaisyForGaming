import re

f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\core\KernelTunable.kt"
src = open(f, encoding="utf-8").read()

pairs = [
    # cpu_min_freq: add policy4/cpu4 after cpu0 fallback
    (r'("(/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq)",\r?\n(\s+)"/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"\n(\s+)\))',
     r'\1\n\2"/sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq",\n\2"/sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq"\n\4)'),
    # cpu_max_freq
    (r'("(/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq)",\r?\n(\s+)"/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"\n(\s+)\))',
     r'\1\n\2"/sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq",\n\2"/sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq"\n\4)'),
    # schedutil up
    (r'("(/sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us)",\r?\n(\s+)"/sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us"\n(\s+)\))',
     r'\1\n\2"/sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us",\n\2"/sys/devices/system/cpu/cpu4/cpufreq/schedutil/up_rate_limit_us"\n\4)'),
    # schedutil down
    (r'("(/sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us)",\r?\n(\s+)"/sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us"\n(\s+)\))',
     r'\1\n\2"/sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us",\n\2"/sys/devices/system/cpu/cpu4/cpufreq/schedutil/down_rate_limit_us"\n\4)'),
]

count = 0
for pat, rep in pairs:
    src, n = re.subn(pat, rep, src)
    count += n

open(f, "w", encoding="utf-8", newline="").write(src)
print("replacements:", count)
