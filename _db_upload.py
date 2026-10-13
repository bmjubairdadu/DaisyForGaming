import json, hashlib, os, shutil, subprocess

DB = "/tmp/kloader_db"
SRC = "/mnt/d/DaisyForGaming/_modules"

# fresh clone of drivers branch
subprocess.run(["rm", "-rf", DB], check=True)
r = subprocess.run(["git", "clone", "--depth", "1", "--branch", "drivers",
                    "https://github.com/bmjubairdadu/kernel-loader.git", DB],
                   capture_output=True, text=True)
if r.returncode != 0:
    print("CLONE FAILED:", r.stderr[-300:])
    raise SystemExit(1)
print("cloned")

man_path = os.path.join(DB, "drivers.json")
man = json.load(open(man_path))

today = "2026-10-13"
updates = 0
for fam_file in ["rt_4.9.337-DaisyForGaming.ko", "qx_4.9.337-DaisyForGaming.ko"]:
    src = os.path.join(SRC, fam_file)
    dst = os.path.join(DB, fam_file)
    shutil.copyfile(src, dst)
    data = open(dst, "rb").read()
    sha = hashlib.sha256(data).hexdigest()
    size = len(data)
    variant = "rt" if fam_file.startswith("rt_") else "qx"
    for e in man["drivers"]:
        if e.get("file") == fam_file:
            e["sha256"] = sha
            e["size"] = size
            e["buildDate"] = today
            updates += 1
            print("updated entry:", fam_file, "size:", size, "sha:", sha[:12])
    # ensure count matches list length
man["count"] = len(man["drivers"])
json.dump(man, open(man_path, "w"), indent=1)
open(man_path, "a").write("\n")
print("entries updated:", updates, "| total drivers:", man["count"])
