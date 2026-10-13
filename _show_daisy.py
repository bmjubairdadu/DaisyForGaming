import json
d = json.load(open("/tmp/kloader/drivers.json"))
for e in d["drivers"]:
    if "DaisyForGaming" in e.get("file", "") or "DaisyForGaming" in e.get("version", ""):
        print(json.dumps(e, indent=1))
