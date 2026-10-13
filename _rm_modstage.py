import re

f = r"D:\DaisyForGaming\dfg_zip.sh"
src = open(f, encoding="utf-8-sig").read()

# 1) remove the AK3 on-device module install block
pat1 = re.compile(
    r"# Install the kernel modules \(CRC-exact for this kernel build\)\.\r?\n"
    r"if \[ -d \./modules \]; then\r?\n"
    r".*?fi;\r?\n\r?\n", re.S)
src, n1 = pat1.subn("", src)

# 2) remove the build-side staging block
pat2 = re.compile(
    r"# Stage the kernel modules \(built from THIS exact kernel tree, CRC-exact\)\r?\n"
    r"if \[ -d \"\$SRC/_modules\" \]; then\r?\n"
    r".*?fi\r?\n", re.S)
src, n2 = pat2.subn("", src)

open(f, "w", encoding="utf-8", newline="").write(src)
print("removed blocks:", n1, n2)
