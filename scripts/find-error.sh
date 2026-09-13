#!/bin/bash
# Find the REAL error in out/build.log (warnings excluded)
LOG=/mnt/d/Kernel/out/build.log
echo '=== REAL ERRORS (warnings excluded) ==='
grep -nE 'error:|Error [0-9]|undefined reference|No such file|No rule to make|Stop\.|failed' "$LOG" | grep -viE 'warning|Wno-|_error\.o|/err\.o' | tail -n 40
echo ''
echo '=== CONTEXT around first fatal ==='
LINE=$(grep -nE 'undefined reference|No rule to make target|Error [0-9]' "$LOG" | head -n 1 | cut -d: -f1)
if [ -n "$LINE" ]; then
  START=$((LINE > 15 ? LINE - 15 : 1))
  END=$((LINE + 10))
  sed -n "${START},${END}p" "$LOG"
else
  echo '--- tail 60 ---'
  tail -n 60 "$LOG"
fi
echo DONE
