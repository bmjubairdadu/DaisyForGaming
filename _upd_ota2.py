import json

f = r"D:\DFG-Controller\app_update.json"
raw = open(f, encoding="utf-8-sig").read()  # tolerate BOM
d = json.loads(raw)
d["latest_version_code"] = 4
d["latest_version_name"] = "1.3"
d["download_url"] = "https://github.com/bmjubairdadu/DFG-Controller/releases/download/v1.3/DFG-Controller-v1.3.apk"
d["sha256"] = "3945b33975bd3fd780f4ebd84d97b7ff1aeac4b5fef70f042d9b6520767ce2cd"
d["release_url"] = "https://github.com/bmjubairdadu/DFG-Controller/releases/tag/v1.3"
d["changelog"] = ("V1.3: kernel auto bypass charging removed (you select games in the app - "
                  "App Bypass handles charging, no more kernel/app charge-toggle races at all). "
                  "Kernel v1.3: 68C CPU throttle, thermal-aware boost, Bypass toggle removed from "
                  "Gaming tab. Everything else unchanged: battery guards on app bypass, "
                  "big-cluster CPU control, fast charge, aggressive LMK.")
with open(f, "w", encoding="utf-8", newline="\n") as fp:
    json.dump(d, fp, indent=2)
    fp.write("\n")
print("app_update.json -> v1.3 (BOM removed)")
