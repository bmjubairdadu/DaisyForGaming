#!/bin/bash
# Map kernel block boundaries + condition lines in matrix3
adb shell grep -n -e '</kernel>' -e 'kernel version' -e 'conditions' /system/etc/vintf/compatibility_matrix.3.xml | head -n 60
