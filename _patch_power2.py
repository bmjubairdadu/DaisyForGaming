f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\ui\screens\PowerScreen.kt"
raw = open(f, "rb").read().decode("utf-8")
nl = "\r\n" if "\r\n" in raw else "\n"

# 1) collect the five per-cleaner busy states instead of the shared one
old = "    val cleanerBusy by viewModel.cleanerBusy.collectAsState()\n"
new = (
    "    val ramCleanBusy by viewModel.ramCleanBusy.collectAsState()\n"
    "    val appCacheCleanBusy by viewModel.appCacheCleanBusy.collectAsState()\n"
    "    val junkFilesCleanBusy by viewModel.junkFilesCleanBusy.collectAsState()\n"
    "    val deepRamCleanBusy by viewModel.deepRamCleanBusy.collectAsState()\n"
    "    val deepJunkCleanBusy by viewModel.deepJunkCleanBusy.collectAsState()\n"
)
assert old in raw, "cleanerBusy collect not found"
src = raw.replace(old, new)

# 2) pair each CleanerCard's busy flag with its own onAction function.
# Work line-based: find each 'onAction = { viewModel.<fn>' line, then walk
# backwards to the nearest 'busy = cleanerBusy' line and set the right flag.
lines = src.split(nl)
flags = {
    "viewModel.cleanRam": "ramCleanBusy",
    "viewModel.cleanAppCaches": "appCacheCleanBusy",
    "viewModel.cleanJunkFiles": "junkFilesCleanBusy",
    "viewModel.deepCleanRam": "deepRamCleanBusy",
    "viewModel.deepCleanJunk": "deepJunkCleanBusy",
}
replaced = 0
for i, ln in enumerate(lines):
    for action, flag in flags.items():
        if action in ln and "onAction" in ln:
            j = i
            while j >= 0:
                if "busy = cleanerBusy" in lines[j]:
                    indent = lines[j][: len(lines[j]) - len(lines[j].lstrip())]
                    lines[j] = f"{indent}busy = {flag},"
                    replaced += 1
                    break
                j -= 1
            break

open(f, "wb").write(src.encode("utf-8"))
print("PowerScreen: busy flags paired =", replaced)
print("leftover shared refs:", src.count("cleanerBusy"))
