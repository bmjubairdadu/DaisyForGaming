import re

f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\core\AppBypassService.kt"
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

# 1) constants: add battery guard thresholds next to SAFETY_TICK_MS
i = find_line('private const val SAFETY_TICK_MS')
if i >= 0:
    indent = lines[i][: len(lines[i]) - len(lines[i].lstrip())]
    ins = [
        indent + 'private const val BYPASS_SOC_MIN = 40      // never bypass below 40%',
        indent + 'private const val BYPASS_SOC_RESUME = 30  // restore charging below 30%',
        indent + 'private const val BYPASS_TEMP_MAX_C = 42  // never bypass above 42C',
        indent + 'private const val BYPASS_TEMP_HOT_C = 45  // force restore above 45C',
    ]
    lines[i+1:i+1] = ins
    added += 4

# 2) battery guard helper before setBypass
i = find_line('private suspend fun setBypass(on: Boolean, message: String)')
if i >= 0:
    indent = lines[i][: len(lines[i]) - len(lines[i].lstrip())]
    ins = [
        indent + '/** Battery state for bypass safety. soc = 0..100 (-1 unknown), tempC or null. */',
        indent + 'private suspend fun batteryState(): Pair<Int, Int?> {',
        indent + '    val soc = ShellManager.readSysfs(SysfsPaths.BATTERY_CAPACITY)',
        indent + '        ?.trim()?.toIntOrNull() ?: -1',
        indent + '    var tempC: Int? = ShellManager.readSysfs(',
        indent + '        "/sys/class/power_supply/battery/temp")',
        indent + '        ?.trim()?.toFloatOrNull()?.let { t ->',
        indent + '            if (t > 300) (t / 10).toInt() else t.toInt()',
        indent + '        }',
        indent + '    return Pair(soc, tempC)',
        indent + '}',
        '',
        indent + '/** Bypass is only safe from a healthy battery window. */',
        indent + 'private suspend fun batterySafeForBypass(): Boolean {',
        indent + '    val (soc, tempC) = batteryState()',
        indent + '    if (soc < 0) return false  // cannot read battery: stay safe',
        indent + '    if (tempC != null && tempC > BYPASS_TEMP_MAX_C) return false',
        indent + '    return soc >= BYPASS_SOC_MIN',
        indent + '}',
        '',
        indent + '/** True when the battery got too low/hot for bypass to stay on. */',
        indent + 'private suspend fun batteryUnsafeForBypass(): Boolean {',
        indent + '    val (soc, tempC) = batteryState()',
        indent + '    if (soc in 0 until BYPASS_SOC_RESUME) return true',
        indent + '    if (tempC != null && tempC > BYPASS_TEMP_HOT_C) return true',
        indent + '    return false',
        indent + '}',
        '',
    ]
    lines[i:i] = ins
    added += len(ins)

open(f, "wb").write(nl.join(lines).encode("utf-8"))
print("inserted:", added)
