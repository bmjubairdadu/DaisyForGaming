import re, subprocess, os

ROOT = "/mnt/d/DaisyForGaming"

# 1) Delete standalone susfs files
for f in ["fs/susfs.c", "fs/sus_su.c", "include/linux/susfs.h", "include/linux/susfs_def.h"]:
    p = os.path.join(ROOT, f)
    if os.path.exists(p):
        os.remove(p)
        print("deleted", f)

# 2) Remove Makefile line
mk = os.path.join(ROOT, "fs/Makefile")
src = open(mk, encoding="utf-8", errors="surrogateescape").read()
lines = [l for l in src.split("\n") if "CONFIG_KSU_SUSFS" not in l]
open(mk, "w", encoding="utf-8", errors="surrogateescape", newline="").write("\n".join(lines))
print("fs/Makefile cleaned")

# 3) Nesting-aware strip of CONFIG_KSU* conditional blocks
FILES = ['fs/namei.c','fs/namespace.c','fs/dcache.c','fs/stat.c','fs/readdir.c',
'fs/proc/fd.c','fs/proc/task_mmu.c','fs/overlayfs/inode.c','fs/overlayfs/readdir.c',
'fs/overlayfs/super.c','fs/overlayfs/overlayfs.h','fs/proc_namespace.c',
'fs/statfs.c','fs/notify/fdinfo.c','kernel/kallsyms.c','kernel/sys.c',
'include/linux/mount.h','include/linux/sched.h']

COND = re.compile(r"^\s*#\s*(if|ifdef|ifndef|else|elif|endif)\b(.*)$", re.I)
HOOK = re.compile(r"CONFIG_KSU")

def strip_susfs(lines):
    out = []
    dropping = 0
    kept_else_stack = []
    i = 0
    n = len(lines)
    while i < n:
        ln = lines[i]
        m = COND.match(ln)
        if m:
            kw, rest = m.group(1).lower(), m.group(2)
            if kw in ("if", "ifdef", "ifndef"):
                is_ksu = bool(HOOK.search(rest))
                if is_ksu:
                    dropping += 1
                    kept_else_stack.append(True)
                    i += 1
                    continue
                out.append(ln)
                kept_else_stack.append(None)
                i += 1
                continue
            if kw == "else":
                if dropping and kept_else_stack and kept_else_stack[-1]:
                    dropping -= 1
                    kept_else_stack[-1] = False
                    kept_else_stack.append("ELSE")
                    i += 1
                    continue
                out.append(ln)
                kept_else_stack.append(None)
                i += 1
                continue
            if kw == "elif":
                if dropping and kept_else_stack and kept_else_stack[-1] is True:
                    i += 1
                    continue
                out.append(ln)
                i += 1
                continue
            if kw == "endif":
                if kept_else_stack:
                    top = kept_else_stack.pop()
                    if top == "ELSE":
                        i += 1
                        continue
                    if top is True and dropping:
                        dropping -= 1
                        i += 1
                        continue
                out.append(ln)
                i += 1
                continue
        if dropping:
            i += 1
            continue
        out.append(ln)
        i += 1
    return out

total = 0
for f in FILES:
    p = os.path.join(ROOT, f)
    if not os.path.exists(p):
        continue
    lines = open(p, encoding="utf-8", errors="surrogateescape").read().split("\n")
    out = strip_susfs(lines)
    open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write("\n".join(out))
    total += 1
print("stripped files:", total)
