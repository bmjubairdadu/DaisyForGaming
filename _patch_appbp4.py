f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\core\AppBypassService.kt"
raw = open(f, "rb").read().decode("utf-8")
nl = "\r\n" if "\r\n" in raw else "\n"

old = (
    "            // The service owns charging while enabled: the kernel's GPU-load\n"
    "            // auto bypass is disabled so it can never fire for a heavy app\n"
    "            // that is not on the user's list.\n"
    "            ShellManager.writeSysfs(SysfsPaths.BYPASS_ON_GAMING, \"N\")\n"
    "\n"
).replace("\n", nl)

if old in raw:
    new = (
        "            // Kernel v1.3 has no auto bypass anymore - charging control is\n"
        "            // fully owned by this service while it runs.\n"
    ).replace("\n", nl)
    raw = raw.replace(old, new)
    open(f, "wb").write(raw.encode("utf-8"))
    print("AppBypassService: kernel bypass write removed")
else:
    print("pattern not found, checking...")
    for i, l in enumerate(raw.split(nl)):
        if "BYPASS_ON_GAMING" in l:
            print(i, repr(l))
