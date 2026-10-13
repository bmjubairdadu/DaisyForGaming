#!/bin/bash
cd /tmp/kloader_db
timeout 150 git push origin drivers > /tmp/push.log 2>&1
echo "push_exit=$?"
cat /tmp/push.log
echo "=== status after ==="
git status -sb | head -1
