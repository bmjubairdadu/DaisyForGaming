import io

f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\core\KernelTunable.kt"
raw = open(f, "rb").read().decode("utf-8")
crlf = "\r\n" in raw
nl = "\r\n" if crlf else "\n"
lines = raw.split(nl)

def find_line(substr, start=0):
    for i in range(start, len(lines)):
        if substr in lines[i]:
            return i
    return -1

added = 0
# --- cpu_min_freq: after the cpu0 fallback line inside its paths list ---
i = find_line('"/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"')
if i >= 0:
    indent = lines[i][: len(lines[i]) - len(lines[i].lstrip())]
    ins = [
        indent + '"/sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq",',
        indent + '"/sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq"',
    ]
    # the cpu0 line currently ends with '"' (no comma) -> give it a comma
    lines[i] = lines[i].rstrip()
    if lines[i].endswith('"'):
        lines[i] += ","
    lines[i+1:i+1] = ins
    added += 2

# --- cpu_max_freq ---
i = find_line('"/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"')
if i >= 0:
    indent = lines[i][: len(lines[i]) - len(lines[i].lstrip())]
    ins = [
        indent + '"/sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq",',
        indent + '"/sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq"',
    ]
    lines[i] = lines[i].rstrip()
    if lines[i].endswith('"'):
        lines[i] += ","
    lines[i+1:i+1] = ins
    added += 2

# --- schedutil up ---
i = find_line('"/sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us"')
if i >= 0:
    indent = lines[i][: len(lines[i]) - len(lines[i].lstrip())]
    ins = [
        indent + '"/sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us",',
        indent + '"/sys/devices/system/cpu/cpu4/cpufreq/schedutil/up_rate_limit_us"',
    ]
    lines[i] = lines[i].rstrip()
    if lines[i].endswith('"'):
        lines[i] += ","
    lines[i+1:i+1] = ins
    added += 2

# --- schedutil down ---
i = find_line('"/sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us"')
if i >= 0:
    indent = lines[i][: len(lines[i]) - len(lines[i].lstrip())]
    ins = [
        indent + '"/sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us",',
        indent + '"/sys/devices/system/cpu/cpu4/cpufreq/schedutil/down_rate_limit_us"',
    ]
    lines[i] = lines[i].rstrip()
    if lines[i].endswith('"'):
        lines[i] += ","
    lines[i+1:i+1] = ins
    added += 2

open(f, "wb").write(nl.join(lines).encode("utf-8"))
print("inserted lines:", added)
