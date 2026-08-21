#!/system/bin/sh
# DaisyForGaming Kernel Magisk Module
# service.sh - Post-install setup for DaisyForGaming kernel features

MODDIR=${0%/*}

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# Apply default DFG performance profile if available
if [ -d "/sys/devices/platform/dfg" ]; then
    # Set performance profile on boot
    echo "performance" > /sys/devices/platform/dfg/profile
    log -t DaisyForGaming "Applied performance profile via Magisk module"
fi

# Apply thermal override if user wants (disabled by default for safety)
# Uncomment the following line to enable thermal override on boot:
# echo 1 > /sys/devices/platform/dfg/thermal_override

# Log module installation
log -t DaisyForGaming "Magisk module installed successfully"

exit 0