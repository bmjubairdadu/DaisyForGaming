#!/usr/bin/env bash
#
# ci/check.sh - static checks for the DaisyForGaming kernel
#
# Runs without a cross toolchain:
#   1. checkpatch on the DFG driver and cpufreq changes
#   2. defconfig sanity (Android 11 + DFG requirements)
#   3. DFG Kconfig symbol cross-check (every CONFIG_DFG_* used in
#      drivers/platform/dfg/ must be defined in its Kconfig)
#   4. shell syntax of the build scripts
#   5. Kconfig/defconfig validation (olddefconfig) when a native
#      compiler is available
#
set -u
FAIL=0

say()  { printf '==> %s\n' "$*"; }
pass() { printf '    PASS: %s\n' "$*"; }
fail() { printf '    FAIL: %s\n' "$*"; FAIL=1; }

DEFCONFIG="arch/arm64/configs/daisy_defconfig"

# --- 1. checkpatch -----------------------------------------------------
say "checkpatch"
if command -v perl >/dev/null 2>&1; then
	./scripts/checkpatch.pl --no-tree --strict \
		drivers/platform/dfg/dfg.c \
		drivers/platform/dfg/Kconfig \
		drivers/cpufreq/cpufreq.c \
		include/linux/cpufreq.h 2>&1 | tail -5
	if [ "${PIPESTATUS[0]}" -eq 0 ]; then
		pass "checkpatch"
	else
		fail "checkpatch (warnings above)"
	fi
else
	echo "    skip (perl not available)"
fi

# --- 2. defconfig sanity ----------------------------------------------
say "defconfig requirements"
for cfg in \
	CONFIG_CGROUPS CONFIG_MEMCG CONFIG_CGROUP_CPUACCT \
	CONFIG_CGROUP_SCHED CONFIG_ANDROID_BINDER_IPC CONFIG_ASHMEM \
	CONFIG_PRINTK CONFIG_CPU_FREQ CONFIG_CPU_FREQ_GOV_SCHEDUTIL \
	CONFIG_DFG CONFIG_DFG_DEFAULT_PERF; do
	if grep -q "^${cfg}=y" "$DEFCONFIG"; then
		pass "$cfg"
	else
		fail "$cfg missing in $DEFCONFIG"
	fi
done

# --- 3. DFG Kconfig cross-check ---------------------------------------
say "DFG Kconfig symbols"
KC=$(sed -n 's/^config \([A-Z0-9_]*\)$/\1/p' drivers/platform/dfg/Kconfig)
MISSING=0
for sym in $(grep -o 'CONFIG_DFG_[A-Z0-9_]*' -r drivers/platform/dfg/dfg.c |
		sed 's/^CONFIG_//' | sort -u); do
	case "$sym" in
		DFG) continue ;; # tristate switch, not a value
	esac
	if ! echo "$KC" | grep -qx "$sym"; then
		printf '    FAIL: %s used but not defined in Kconfig\n' "$sym"
		MISSING=1
		FAIL=1
	fi
done
[ "$MISSING" -eq 0 ] && pass "DFG Kconfig symbols"

# --- 4. shell syntax ---------------------------------------------------
say "shell syntax"
for sh in build_kernel.sh ci/check.sh; do
	if sh -n "$sh" 2>/dev/null; then
		pass "$sh"
	else
		fail "$sh has syntax errors"
	fi
done

# --- 5. kconfig validation (needs native gcc) -------------------------
say "defconfig validation (olddefconfig)"
if command -v gcc >/dev/null 2>&1; then
	rm -rf /tmp/dfg-kconfig-check
	cp "$DEFCONFIG" /tmp/dfg-kconfig-check-defconfig
	if make O=/tmp/dfg-kconfig-check ARCH=arm64 \
	     "$DEFCONFIG" >/dev/null 2>&1 && \
	   make O=/tmp/dfg-kconfig-check ARCH=arm64 \
	     olddefconfig >/dev/null 2>&1; then
		pass "defconfig parses cleanly"
	else
		fail "defconfig validation failed"
	fi
	rm -rf /tmp/dfg-kconfig-check /tmp/dfg-kconfig-check-defconfig
else
	echo "    skip (gcc not available)"
fi

exit "$FAIL"