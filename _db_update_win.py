import json, hashlib, os

DB = os.path.join(os.environ["TEMP"], "kloader_db")
SRC = r"D:\DaisyForGaming\_modules"

# restore pristine manifest first (may have been clobbered)
os.system(f'git -C "{DB}" checkout -- drivers.json')

man_path = os.path.join(DB, "drivers.json")
man = json.load(open(man_path, encoding="utf-8"))

today = "2026-10-13"
updates = 0
for fam_file in ["rt_4.9.337-DaisyForGaming.ko", "qx_4.9.337-DaisyForGaming.ko"]:
    p = os.path.join(SRC, fam_file)
    data = open(p, "rb").read()
    sha = hashlib.sha256(data).hexdigest()
    size = len(data)
    for e in man["drivers"]:
        if e.get("file") == fam_file:
            e["sha256"] = sha
            e["size"] = size
            e["buildDate"] = today
            updates += 1
            print("updated:", fam_file, "size:", size, "sha:", sha[:12])

man["count"] = len(man["drivers"])
with open(man_path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(man, f, indent=1)
    f.write("\n")
print("updates:", updates)
