# DaisyForGaming external driver modules

Build out-of-tree `.ko` drivers matching the running
`4.9.337-DaisyForGaming` kernel (vermagic-compatible, CRCs from
`Module.symvers`).

## Needs (one time)

- This kernel source at the exact release commit
- Matching `.config` + generated `Module.symvers` (run a full kernel
  build first: `make O=out ARCH=arm64 daisy_defconfig` then `make`)
- `gcc-11-aarch64-linux-gnu` + `gcc-11-arm-linux-gnueabi` toolchain

## Build any driver (example: daisy_hello)

```bash
cd modules/daisy_hello
make -C <KERNEL>/out M=$PWD ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  LD=aarch64-linux-gnu-ld modules
```

## Load on phone (root required)

```sh
adb push daisy_hello.ko /data/local/tmp/
adb shell su -c 'insmod /data/local/tmp/daisy_hello.ko'
adb shell su -c 'dmesg | tail -3'   # expect: hello module loaded!
adb shell su -c 'rmmod daisy_hello'
```

## Notes

- The kernel accepts any-version `.ko` (vermagic bypass), but unknown
  kernel symbols still fail the load — build against THIS tree.
- Closed-source drivers must match this kernel's memory layout/ABI;
  a `.ko` built for another device/kernel may crash — test carefully.
