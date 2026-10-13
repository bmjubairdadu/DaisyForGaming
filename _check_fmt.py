import json, hashlib, os, subprocess

DB = os.path.join(os.environ["TEMP"], "kloader_db")

# get the pristine file exactly as committed (raw bytes)
r = subprocess.run(["git", "-C", DB, "show", "HEAD:drivers.json"],
                   capture_output=True)
raw = r.stdout
print("pristine bytes:", len(raw))
print("has CRLF:", b"\r\n" in raw)
print("first 120 bytes:", raw[:120])
print("last 60 bytes:", raw[-60:])

# check current working copy
cur = open(os.path.join(DB, "drivers.json"), "rb").read()
print("current bytes:", len(cur), "CRLF:", b"\r\n" in cur)
