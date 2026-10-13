import json
d = json.load(open("/tmp/kloader/drivers.json"))
print(json.dumps(d, indent=1)[:1800])
