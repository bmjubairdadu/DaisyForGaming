src = open("/mnt/d/DaisyForGaming/drivers/cpufreq/cpu-boost.c",
           encoding="utf-8", errors="surrogateescape").read()
print("usb_charger_online count:", src.count("usb_charger_online"))
print("power_supply include:", "#include <linux/power_supply.h>" in src)
