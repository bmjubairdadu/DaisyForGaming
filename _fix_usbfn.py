p = "/mnt/d/DaisyForGaming/drivers/cpufreq/cpu-boost.c"
src = open(p, encoding="utf-8", errors="surrogateescape").read()

helper = (
    "/* Battery temperature in tenths of a degree C, or -1 if unavailable. */\n"
    "static int batt_temp_tenths(void)\n"
)
usb_fn = (
    "static bool usb_charger_online(void)\n"
    "{\n"
    "\tstruct power_supply *usb;\n"
    "\tunion power_supply_propval val = { 0, };\n"
    "\tbool online = false;\n"
    "\n"
    "\tusb = power_supply_get_by_name(\"usb\");\n"
    "\tif (!usb)\n"
    "\t\treturn false;\n"
    "\n"
    "\tif (!power_supply_get_property(usb, POWER_SUPPLY_PROP_PRESENT, &val))\n"
    "\t\tonline = !!val.intval;\n"
    "\telse if (!power_supply_get_property(usb, POWER_SUPPLY_PROP_ONLINE, &val))\n"
    "\t\tonline = !!val.intval;\n"
    "\tpower_supply_put(usb);\n"
    "\n"
    "\treturn online;\n"
    "}\n"
    "\n"
)
assert src.count("usb_charger_online") == 1 and helper in src
src = src.replace(helper, usb_fn + helper)
open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(src)
print("usb_charger_online restored; count:", src.count("usb_charger_online"))
