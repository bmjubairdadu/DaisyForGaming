#!/bin/bash
# Dump all VINTF kernel config keys from level-3 matrix on device
adb_bin="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
"$adb_bin" shell "cat /system/etc/vintf/compatibility_matrix.3.xml" | grep -A2 "<key>CONFIG_" | grep -E "key>|value" | sed 's/^ *//' > /tmp/vintf_keys.txt || true
cat /tmp/vintf_keys.txt
