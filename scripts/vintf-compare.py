#!/usr/bin/env python3
"""Compare VINTF framework matrix kernel requirements vs live /proc/config.gz."""
import re, sys

matrix = open("D:/Kernel/out/matrix3-k49.xml", encoding="utf-8", errors="replace").read()
live = {}
for line in open("D:/Kernel/out/live-config.txt", encoding="utf-8", errors="replace"):
    line = line.strip()
    m = re.match(r"^(CONFIG_[A-Za-z0-9_]+)=(.*)$", line)
    if m:
        live[m.group(1)] = m.group(2).strip().strip('"')
    m2 = re.match(r"^#\s*(CONFIG_[A-Za-z0-9_]+)\s+is not set$", line)
    if m2:
        live[m2.group(1)] = "n"

reqs = re.findall(r"<key>(CONFIG_[A-Za-z0-9_]+)</key>\s*<value type=\"([a-z]+)\"[^>]*>(.*?)</value>", matrix, re.S)
print(f"Total VINTF kernel requirements: {len(reqs)}")
mismatch = []
ok = 0
for key, typ, want in reqs:
    want = want.strip()
    got = live.get(key, "<MISSING>")
    good = False
    if typ == "tristate":
        if want == "y":
            good = got in ("y", "m")
        elif want == "n":
            good = got == "n"
        elif want == "m":
            good = got == "m"
    elif typ == "string":
        good = got == want.strip('"')
    elif typ == "int":
        try:
            good = int(got, 0) == int(want, 0)
        except Exception:
            good = False
    elif typ == "bool":
        good = (got == "y") == (want == "y")
    elif typ == "range":
        lo, hi = want.split("-")
        try:
            good = int(lo, 0) <= int(got, 0) <= int(hi, 0)
        except Exception:
            good = False
    else:
        good = got == want
    if good:
        ok += 1
    else:
        mismatch.append((key, typ, want, got))

print(f"OK: {ok}, MISMATCH: {len(mismatch)}")
print("=== MISMATCHES (want vs live) ===")
for key, typ, want, got in mismatch:
    print(f"{key} type={typ} want={want!r} live={got!r}")
