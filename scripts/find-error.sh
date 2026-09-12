#!/bin/bash
grep -B5 -A15 'Error 2' /root/daisy-build/out/build-final.log | head -n 60
echo '=== FIRST ERROR LINE ==='
grep -n 'error' /root/daisy-build/out/build-final.log | head -10
echo DONE
