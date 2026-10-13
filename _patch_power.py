import re

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
).replace("\n", nl) + ("\n" if raw.count(old) else "")
assert old.replace("\n", nl) in raw, "cleanerBusy collect not found"
src = raw.replace(old.replace("\n", nl), new)

# 2) pair each CleanerCard's busy flag with its own onAction function
pairs = [
    ("viewModel.cleanRam", "ramCleanBusy"),
    ("viewModel.cleanAppCaches", "appCacheCleanBusy"),
    ("viewModel.cleanJunkFiles", "junkFilesCleanBusy"),
    ("viewModel.deepCleanRam", "deepRamCleanBusy"),
    ("viewModel.deepCleanJunk", "deepJunkCleanBusy"),
]
replaced = 0
for action, flag in pairs:
    # within each CleanerCard block: busy = cleanerBusy ... onAction = { viewModel.<fn>
    pat = re.compile(
        r"(busy = )cleanerBusy(,\r?\n(?:(?!CleanerCard\().)*?onAction = \{ " +
        re.escape(action))
    src, n = pat.subn(r"\1" + flag + r"\2", src)
    replaced += n

open(f, "wb").write(src.encode("utf-8"))
print("PowerScreen: busy flags paired =", replaced)
print("leftover shared refs:", src.count("cleanerBusy"))
