f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\core\AppBypassService.kt"
raw = open(f, "rb").read().decode("utf-8")
nl = "\r\n" if "\r\n" in raw else "\n"

dead = (
    '        if (!on && bypassApplied && !batteryUnsafeForBypass() && screenOn) {\n'
    '            // normal off-path (app closed) - keep going below\n'
    '        }\n'
).replace("\n", nl)
assert dead in raw, "dead block not found"
src = raw.replace(dead, "")
open(f, "wb").write(src.encode("utf-8"))
print("dead block removed")
