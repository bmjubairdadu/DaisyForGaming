import json, hashlib, os, subprocess

DB = os.path.join(os.environ["TEMP"], "kloader_db")
SRC = r"D:\DaisyForGaming\_modules"

# restore pristine formatting from the commit BEFORE our noisy one
r = subprocess.run(["git", "-C", DB, "show", "HEAD~1:drivers.json"],
                   capture_output=True)
raw = r.stdout.decode("utf-8")
man = json.loads(raw)

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

man["count"] = len(man["drivers"])
out = json.dumps(man, indent=2)
if not out.endswith("\n"):
    out += "\n"
with open(os.path.join(DB, "drivers.json"), "w", encoding="utf-8", newline="\n") as f:
    f.write(out)
print("updates:", updates, "- file rewritten with 2-space indent")
