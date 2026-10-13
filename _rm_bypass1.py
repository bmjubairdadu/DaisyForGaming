import re

p = "/mnt/d/DaisyForGaming/drivers/cpufreq/cpu-boost.c"
src = open(p, encoding="utf-8", errors="surrogateescape").read()

# ---- 1) constants block: rewrite to thermal-only ----
old_block_start = src.find("/*\n * Thermal + battery guards")
old_block_end = src.find("#define DFG_BOOST_TEMP_HOT")
assert old_block_start > 0 and old_block_end > old_block_start, "const block"
new_block = (
    "/*\n"
    " * Thermal guard (DaisyForGaming v1.3):\n"
    " * Boost steps down when the battery runs hot, so the device stays safe\n"
    " * even when no controller app runs (CPU throttling starts at 68C via DT).\n"
    " */\n"
    "#define DFG_BOOST_TEMP_WARM\t50000\t/* drop to balanced above 50.0C */\n"
)
src = src[:old_block_start] + new_block + src[old_block_end:]

# ---- 2) helpers -> slim temp reader (note: comment uses single-star) ----
m = re.search(
    r"static bool usb_charger_online\(void\)\n\{.*?\n\}\n\n/\*\n \* Battery guards:.*?static bool battery_safe_for_bypass\(unsigned int \*soc_out, int \*temp_out\)\n\{.*?\n\}\n",
    src, re.S)
assert m, "helpers block not found"
helpers_new = (
    "/* Battery temperature in tenths of a degree C, or -1 if unavailable. */\n"
    "static int batt_temp_tenths(void)\n"
    "{\n"
    "\tstruct power_supply *batt;\n"
    "\tunion power_supply_propval val = { 0, };\n"
    "\tint temp = -1;\n"
    "\n"
    "\tbatt = power_supply_get_by_name(\"battery\");\n"
    "\tif (!batt)\n"
    "\t\treturn -1;\n"
    "\tif (!power_supply_get_property(batt, POWER_SUPPLY_PROP_TEMP, &val))\n"
    "\t\ttemp = val.intval;\n"
    "\tpower_supply_put(batt);\n"
    "\treturn temp;\n"
    "}\n"
)
src = src[:m.start()] + helpers_new + src[m.end():]

open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(src)
print("phase1 ok")
