f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\ui\screens\PowerScreen.kt"
raw = open(f, "rb").read().decode("utf-8")
nl = "\r\n" if "\r\n" in raw else "\n"
lines = raw.split(nl)

# where did the 5 earlier replacements land?
marks = ["ramCleanBusy", "appCacheCleanBusy", "junkFilesCleanBusy",
         "deepRamCleanBusy", "deepJunkCleanBusy"]
print("existing per-flag lines:")
for i, ln in enumerate(lines):
    for m in marks:
        if f"busy = {m}" in ln:
            print(f"  {i+1}: {ln.strip()}")

# description -> flag mapping (the 5 MAINTENANCE cards)
desc_flag = [
    ("Kill background processes and drop the page cache", "ramCleanBusy"),
    ("Trim cached data of every installed app", "appCacheCleanBusy"),
    ("Clear /data/local/tmp, DCIM thumbnails", "junkFilesCleanBusy"),
    ("background kill + full page-cache drop + ZRAM compact", "deepRamCleanBusy"),
    ("every app's external cache + code_cache", "deepJunkCleanBusy"),
]
fixed = 0
for i, ln in enumerate(lines):
    for desc, flag in desc_flag:
        if desc in ln:
            # the busy line is within the next 3 lines
            for j in range(i + 1, min(i + 4, len(lines))):
                if "busy = " in lines[j]:
                    indent = lines[j][: len(lines[j]) - len(lines[j].lstrip())]
                    want = f"{indent}busy = {flag},"
                    if lines[j] != want:
                        lines[j] = want
                        fixed += 1
                    break
open(f, "wb").write(raw.encode("utf-8"))
print("pre-write fixed:", fixed)

# rewrite with the fixed content
open(f, "wb").write(nl.join(lines).encode("utf-8"))
print("done")
