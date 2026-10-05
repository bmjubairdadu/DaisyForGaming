import struct, sys, os

SRC = r"D:\DaisyForGaming\_folkpatch_tools\boot_template.img"

def parse_hdr(buf):
    assert buf[:8] == b"ANDROID!", "not a boot image"
    f = struct.unpack_from("<10I", buf, 8)
    name = buf[0x30:0x40].rstrip(b"\0").decode(errors="replace")
    cmdline = buf[0x40:0x240].rstrip(b"\0").decode(errors="replace")
    extra = buf[0x260:0x660].rstrip(b"\0").decode(errors="replace")
    return dict(kernel_size=f[0], kernel_addr=f[1], ramdisk_size=f[2],
                ramdisk_addr=f[3], second_size=f[4], second_addr=f[5],
                tags_addr=f[6], page_size=f[7], hdr_ver=f[8], os_ver=f[9],
                name=name, cmdline=cmdline, extra_cmdline=extra)

def load_parts(path):
    buf = open(path, "rb").read()
    h = parse_hdr(buf)
    ps = h["page_size"]
    n = lambda sz: ((sz + ps - 1) // ps) if sz else 0
    off = ps  # header occupies 1 page
    kern = buf[off:off + h["kernel_size"]]
    off += n(h["kernel_size"]) * ps
    rd = buf[off:off + h["ramdisk_size"]]
    off += n(h["ramdisk_size"]) * ps
    sec = buf[off:off + h["second_size"]]
    off += n(h["second_size"]) * ps
    tail_used = off
    return h, kern, rd, sec, tail_used, len(buf)

def build(h, kern, rd, sec, out):
    ps = h["page_size"]
    pad = lambda b: b + b"\0" * ((-len(b)) % ps)
    hdr = bytearray(open(SRC, "rb").read()[:ps])  # copy original header page
    struct.pack_into("<I", hdr, 8, len(kern))      # kernel_size
    img = bytes(hdr)
    img += pad(kern)
    img += pad(rd) if rd else b""
    img += pad(sec) if sec else b""
    open(out, "wb").write(img)
    return len(img)

h, kern, rd, sec, used, total = load_parts(SRC)
print(f"header: kernel_size={h['kernel_size']:#x} ramdisk_size={h['ramdisk_size']:#x} "
      f"second_size={h['second_size']:#x} page={h['page_size']} hdr_ver={h['hdr_ver']}")
print(f"cmdline: {h['cmdline'][:80]!r}")
print(f"parts: used={used:#x} total={total:#x}")

for tag, img in (("clean_fp_boot.img",
                  r"D:\DaisyForGaming\out-fp\arch\arm64\boot\Image.gz-dtb"),):
    kb = open(img, "rb").read()
    out = rf"D:\DaisyForGaming\_folkpatch_tools\{tag}"
    sz = build(h, kb, rd, sec, out)
    print(f"built {tag}: {sz} bytes (kernel {len(kb)} bytes)")

for tag in ("clean_fp_boot.img",):
    h2, k2, r2, s2, _, _ = load_parts(rf"D:\DaisyForGaming\_folkpatch_tools\{tag}")
    ok = (r2 == rd) and h2["kernel_size"] == len(k2)
    print(f"verify {tag}: ramdisk_identical={r2 == rd} kernel_size={h2['kernel_size']} -> {'OK' if ok else 'FAIL'}")
