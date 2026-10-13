import re

p = "/mnt/d/DaisyForGaming/drivers/cpufreq/cpu-boost.c"
src = open(p, encoding="utf-8", errors="surrogateescape").read()

# 1) remove bypass work decl + forward decl
src = src.replace(
    "static void bypass_check_work(struct work_struct *work);\n"
    "static DECLARE_DELAYED_WORK(bypass_work, bypass_check_work);\n", "")
src = src.replace("\t\n\tschedule_delayed_work(&bypass_work, 0);\n}\n", "}\n")

# 2) auto_boost_tick thermal block: battery_safe_for_bypass(NULL,...) -> batt_temp_tenths()
src = src.replace(
    "\tbattery_safe_for_bypass(NULL, &batt_temp);\n\tif (batt_temp > 0) {",
    "\tbatt_temp = batt_temp_tenths();\n\tif (batt_temp > 0) {")

# 3) remove whole bypass section: param + set_battery_charging + bypass_check_work
m = re.search(
    r"static bool bypass_on_gaming = true;\n"
    r"module_param\(bypass_on_gaming, bool, 0644\);\n"
    r"MODULE_PARM_DESC\(bypass_on_gaming,\n"
    r"\t\"Inhibit battery charging while gaming on the charger \(bypass: USB feeds the board\)\"\);\n"
    r"\n"
    r"static bool bypass_active, psy_ready;\n"
    r"static unsigned int bypass_passes;\n"
    r"\n"
    r"static void set_battery_charging\(bool enable\)\n"
    r"\{.*?\n\}\n"
    r"\n"
    r"static void bypass_check_work\(struct work_struct \*work\)\n"
    r"\{.*?\n\}\n",
    src, re.S)
assert m, "bypass section not found"
src = src[:m.start()] + src[m.end():]

# 4) remove psy notifier
m = re.search(
    r"static int cpuboost_psy_notifier\(struct notifier_block \*nb, unsigned long event,\n"
    r"\t\t\t\t void \*data\)\n"
    r"\{\n"
    r"\tif \(event == PSY_EVENT_PROP_CHANGED && data &&\n"
    r"\t    !strcmp\(\(const char \*\)data, \"usb\"\)\)\n"
    r"\t\tschedule_delayed_work\(&bypass_work, 0\);\n"
    r"\n"
    r"\treturn NOTIFY_OK;\n"
    r"\}\n"
    r"static struct notifier_block cpuboost_psy_nb = \{\n"
    r"\t\.notifier_call = cpuboost_psy_notifier,\n"
    r"\};\n\n",
    src)
assert m, "psy notifier not found"
src = src[:m.start()] + src[m.end():]

# 5) init: remove psy register + psy_ready + bypass kick
src = src.replace(
    "\tfb_register_client(&cpuboost_fb_nb);\n"
    "\tpower_supply_reg_notifier(&cpuboost_psy_nb);\n"
    "\tpsy_ready = true;\n"
    "\tschedule_delayed_work(&bypass_work, 0);\n",
    "\tfb_register_client(&cpuboost_fb_nb);\n")

# 6) set_boost_profile: remove bypass kick (already removed via #1? verify)
src = src.replace("\t\n\tschedule_delayed_work(&bypass_work, 0);\n}\n", "}\n")
# some variants have different whitespace
src = re.sub(r"\n\t*schedule_delayed_work\(&bypass_work, 0\);", "", src)
src = re.sub(r"\n\t*schedule_delayed_work\(&bypass_work, msecs_to_jiffies\(2000\)\);", "", src)

open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(src)

# verify nothing bypass-related remains
left = [l for l in src.split("\n") if re.search(r"bypass|bypass_work|psy_ready|bypass_on_gaming|set_battery_charging|cpuboost_psy", l)]
print("remaining bypass refs:", len(left))
for l in left[:10]:
    print("  ", l.strip())
print("phase2 ok")
