#!/bin/bash
# Build RT + QX modules against the fresh kernel build
set -e
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1
KSRC=/mnt/d/DaisyForGaming
KOUT=$KSRC/out
WORK=/tmp/modbuild
rm -rf $WORK && mkdir -p $WORK/rt $WORK/qx
cp /tmp/kloader/driver/memacc.c $WORK/rt/memacc.c
cp /tmp/kloader/driver/kmem_337_core.h $WORK/rt/kmem_337_core.h
cp /tmp/kloader/driver/memacc_qx.c $WORK/qx/memacc_qx.c
cp /tmp/kloader/driver/kmem_337_core.h $WORK/qx/kmem_337_core.h
printf 'obj-m += memacc.o\n' > $WORK/rt/Makefile
printf 'obj-m += memacc_qx.o\n' > $WORK/qx/Makefile
cd $WORK/rt
make -C $KSRC O=$KOUT ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=clang M=$WORK/rt modules 2>&1 | tail -4
cd $WORK/qx
make -C $KSRC O=$KOUT ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=clang M=$WORK/qx modules 2>&1 | tail -4
echo "=== vermagic + crc check ==="
for k in $WORK/rt/memacc.ko $WORK/qx/memacc_qx.ko; do
  echo "--- $k"
  modinfo $k 2>/dev/null | grep -E 'vermagic|name' || strings $k | grep -m1 vermagic
  readelf -S $k 2>/dev/null | grep -c '__versions' || true
done
mkdir -p /tmp/modbuild/stage
cp $WORK/rt/memacc.ko /tmp/modbuild/stage/rt_4.9.337-DaisyForGaming.ko
cp $WORK/qx/memacc_qx.ko /tmp/modbuild/stage/qx_4.9.337-DaisyForGaming.ko
ls -la /tmp/modbuild/stage/
echo MODULES_DONE
