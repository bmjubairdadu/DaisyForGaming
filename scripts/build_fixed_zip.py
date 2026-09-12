# DaisyForGaming v2.1 4.9.337 - TWRP-compliant repack helper
# build.sh already makes the zip; this script repacks it STORE-only.
import sys, zipfile
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "out"
cands = sorted(OUT.glob("DaisyForGaming-v2.1-Gaming-4.9.337-*.zip"))
if not cands:
    print("No DaisyForGaming v2.1 zip found in out/")
    sys.exit(1)
src = cands[-1]
dst = OUT / (src.stem + "-fixed.zip")
with zipfile.ZipFile(src, "r") as zin, zipfile.ZipFile(dst, "w", zipfile.ZIP_STORED) as zout:
    for item in zin.infolist():
        zout.writestr(item, zin.read(item.filename))
print(f"Repacked: {dst}")
