#!/bin/bash
# Extract ONLY the 4.9 kernel sections from matrix3.xml on device
adb_bin="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
"$adb_bin" shell "sed -n '/<kernel version=\"4.9/,/<\/kernel>/p' /system/etc/vintf/compatibility_matrix.3.xml" > D:/Kernel/out/matrix3-k49.xml
wc -l D:/Kernel/out/matrix3-k49.xml
grep -c "<key>CONFIG_" D:/Kernel/out/matrix3-k49.xml
