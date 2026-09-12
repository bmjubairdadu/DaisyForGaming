#!/bin/bash
# Verifies the AnyKernel3 premium banner marker is present.
# DaisyForGaming by JUBAIR HOSEN | 4.9.337 Safe (No Pre-Root)
set -e
AK3_SH="${1:-AnyKernel3/anykernel.sh}"
grep -q "DaisyForGaming by JUBAIR HOSEN" "$AK3_SH" || {
  echo "Banner marker missing in $AK3_SH"
  exit 1
}
echo "Banner OK: DaisyForGaming premium flash UI present."
