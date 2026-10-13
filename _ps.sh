#!/bin/bash
echo "=== all make/clang/ld processes ==="
ps -eo pid,etime,comm,args --sort=start_time | grep -E 'make|clang|ld\.lld' | grep -v grep | head -25
echo
echo "=== make instance count ==="
pgrep -c make || echo 0
