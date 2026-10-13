import re

f = r"D:\DaisyForGaming\dfg_tune.sh"
src = open(f, encoding="utf-8").read()

pat = re.compile(
    r"\n# Load DFG kernel modules \(CRC-exact build\)\. vermagic mismatch = skipped\.\r?\n"
    r"if \[ -d /data/adb/dfg_modules \]; then\r?\n"
    r".*?fi\r?\n", re.S)
src, n = pat.subn("\n", src)
open(f, "w", encoding="utf-8", newline="").write(src)
print("removed:", n)
print("dfg_modules refs left:", src.count("dfg_modules"))
