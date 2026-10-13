import re

f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\core\AppBypassService.kt"
raw = open(f, "rb").read().decode("utf-8")
crlf = "\r\n" in raw
nl = "\r\n" if crlf else "\n"

# 1) setBypass: gate engagement on battery safety
old1 = (
    '    private suspend fun setBypass(on: Boolean, message: String) {\n'
    '        if (bypassApplied == on) return\n'
    '        val ok = ShellManager.writeSysfs(SysfsPaths.BATTERY_CHARGING_ENABLED, if (on) "0" else "1")\n'
)
new1 = (
    '    private suspend fun setBypass(on: Boolean, message: String) {\n'
    '        if (bypassApplied == on) return\n'
    '        // Battery guards: never ENGAGE bypass from a low/hot battery, and\n'
    '        // force a restore if the battery dropped while bypass was on.\n'
    '        if (on && !batterySafeForBypass()) {\n'
    '            updateNotification("Bypass blocked \\u2014 battery low or hot")\n'
    '            return\n'
    '        }\n'
    '        if (!on && bypassApplied && !batteryUnsafeForBypass() && screenOn) {\n'
    '            // normal off-path (app closed) - keep going below\n'
    '        }\n'
    '        val ok = ShellManager.writeSysfs(SysfsPaths.BATTERY_CHARGING_ENABLED, if (on) "0" else "1")\n'
)
assert old1.replace('\n', nl) in raw, "setBypass block not found"
src = raw.replace(old1.replace('\n', nl), new1.replace('\n', nl))

# 2) safety loop: force restore when battery unsafe, before desired-state logic
old2 = (
    '                } else {\n'
    '                    val fg = currentForegroundPackage()\n'
    '                    val desired = screenOn && currentApps.contains(fg)\n'
)
new2 = (
    '                } else {\n'
    '                    // Battery safety first: low/hot battery always wins.\n'
    '                    if (bypassApplied && batteryUnsafeForBypass()) {\n'
    '                        setBypass(false, "Battery low/hot \\u2014 charging restored")\n'
    '                        delay(SAFETY_TICK_MS)\n'
    '                        continue\n'
    '                    }\n'
    '                    // Do not ENGAGE while the battery is outside the safe window.\n'
    '                    val fg = currentForegroundPackage()\n'
    '                    val desired = screenOn && currentApps.contains(fg) &&\n'
    '                        batterySafeForBypass()\n'
)
assert old2.replace('\n', nl) in src, "safety loop block not found"
src = src.replace(old2.replace('\n', nl), new2.replace('\n', nl))

open(f, "wb").write(src.encode("utf-8"))
print("patched: setBypass gate + safety loop guard")
