#!/bin/bash
ls /root/daisy-build/toolchain/proton-clang/bin/ld.lld
echo '--- LD config lines ---'
grep -E 'LD_' /root/daisy-build/kernel_source/out/.config | head -10
echo LD_CHECK_DONE
