#!/bin/bash
S=/root/daisy-build/kernel_source
C="$S/out/.config"
echo "--- kallsyms detail ---"
grep -E "KALLSYMS" "$C"
echo "--- modules ---"
grep -E "^CONFIG_MODULES|MODULE_UNLOAD|MODVERSIONS" "$C" | head -5
echo "--- kprobes/ftrace ---"
grep -E "^CONFIG_KPROBES|^CONFIG_KRETPROBES|^CONFIG_FTRACE|^CONFIG_FUNCTION_TRACER|^CONFIG_KPROBES_ON_FTRACE" "$C" | head -8
echo "--- kptr/printk ---"
grep -E "KPTR|PRINTK" "$C" | head -5
echo "--- seccomp (KP needs?) ---"
grep -E "^CONFIG_SECCOMP" "$C"
echo "--- arm64 page table / KASLR ---"
grep -E "RANDOMIZE_BASE|RELOCATABLE|KASLR" "$C" | head -5
echo "--- Kconfig: KALLSYMS_ALL exists in tree? ---"
grep -n -A3 "config KALLSYMS_ALL" "$S/init/Kconfig" | head -8
echo "--- Kconfig: KPROBES exists? ---"
grep -n "config KPROBES" "$S/arch/arm64/Kconfig" "$S/kernel/Kconfig.kprobes" 2>/dev/null | head -5
