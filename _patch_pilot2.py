import re

# AutoPilotService: kernelOwns check is now pointless (kernel has no bypass).
# Restore straightforward 85% battery-rest bypass logic (keep temp safety).
f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\core\AutoPilotService.kt"
raw = open(f, "rb").read().decode("utf-8")
nl = "\r\n" if "\r\n" in raw else "\n"

old = (
    "            // Only owned here when app-triggered bypass is not running.\n"
    "            // SAFETY: never fight the kernel's gaming bypass. When the kernel\n"
    "            // is in the gaming profile (boost_mode_effective == 2) it owns the\n"
    "            // charge path with its own battery/temp guards - touching the node\n"
    "            // here caused charge-toggle races (heat + reboots).\n"
    "            val kernelOwns = ShellManager.readSysfs(SysfsPaths.BOOST_MODE_EFFECTIVE)\n"
    "                ?.trim() == \"2\"\n"
    "            val battTempSafe = tempC < THERMAL_SUSPEND_C - 5\n"
    "            if (charging && cap >= BYPASS_ENGAGE_PCT && !bypassEngaged &&\n"
    "                !kernelOwns && battTempSafe\n"
    "            ) {\n"
).replace("\n", nl)
new = (
    "            // Only owned here when app-triggered bypass is not running.\n"
    "            // Battery guards stay: skip engaging when the phone is hot.\n"
    "            val battTempSafe = tempC < THERMAL_SUSPEND_C - 5\n"
    "            if (charging && cap >= BYPASS_ENGAGE_PCT && !bypassEngaged &&\n"
    "                battTempSafe\n"
    "            ) {\n"
).replace("\n", nl)

assert old in raw, "autopilot block v2 not found"
src = raw.replace(old, new)

old2 = (
    "            } else if ((!charging || cap < BYPASS_RELEASE_PCT || kernelOwns) && bypassEngaged) {\n"
).replace("\n", nl)
new2 = (
    "            } else if ((!charging || cap < BYPASS_RELEASE_PCT) && bypassEngaged) {\n"
).replace("\n", nl)
assert old2 in src, "release line not found"
src = src.replace(old2, new2)

open(f, "wb").write(src.encode("utf-8"))
print("AutoPilotService simplified (kernelOwns removed)")
