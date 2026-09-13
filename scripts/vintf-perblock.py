#!/usr/bin/env python3
"""Split matrix3.xml into kernel blocks, show version/conditions/configs,
then compare each block vs live config to find which block our kernel hits."""
import re

matrix = open("D:/Kernel/out/matrix3.xml", encoding="utf-8", errors="replace").read()
live = {}
for line in open("D:/Kernel/out/live-config.txt", encoding="utf-8", errors="replace"):
    line = line.strip()
    m = re.match(r"^(CONFIG_[A-Za-z0-9_]+)=(.*)$", line)
    if m:
        live[m.group(1)] = m.group(2).strip().strip('"')
    m2 = re.match(r"^#\s*(CONFIG_[A-Za-z0-9_]+)\s+is not set$", line)
    if m2:
        live[m2.group(1)] = "n"

blocks = re.findall(r"<kernel version=\"([^\"]+)\"(?: level=\"([^\"]+)\")?>(.*?)</kernel>", matrix, re.S)
print(f"Total kernel blocks: {len(blocks)}")
for i, (ver, lvl, body) in enumerate(blocks):
    cond = re.findall(r"<conditions>(.*?)</conditions>", body, re.S)
    cfgs = re.findall(r"<key>(CONFIG_[A-Za-z0-9_]+)</key>\s*<value type=\"([a-z]+)\"[^>]*>(.*?)</value>", body, re.S)
    print(f"\n--- BLOCK {i}: version={ver} level={lvl} configs={len(cfgs)} ---")
    for c in cond:
        print("COND:", re.sub(r"\s+", " ", c).strip()[:400])
    mm = []
    for key, typ, want in cfgs:
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
        else:
            good = got == want
        if not good:
            mm.append((key, typ, want, got))
    print(f"MISMATCH in block {i}: {len(mm)}")
    for key, typ, want, got in mm:
        print(f"  {key} type={typ} want={want!r} live={got!r}")
