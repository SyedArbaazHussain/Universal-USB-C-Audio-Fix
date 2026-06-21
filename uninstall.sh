#!/system/bin/sh
# ============================================================================
# USB-C DAC Volume Control Fix - Uninstall Script
# Version: 14.0
# Purpose: Clean removal of module and restoration of original state
# ============================================================================

# This script is automatically called when the module is uninstalled
# It performs cleanup and restores the original audio configuration

MODPATH=${0%/*}
LOGFILE="/data/adb/usb_dac_volume.log"

echo "[UNINSTALL] Module removal initiated" >> "$LOGFILE"

# ============================================================================
# CLEANUP STATE FILES
# ============================================================================

# Remove module state directory
rm -rf /data/adb/usb_dac_volume_state 2>/dev/null || true
echo "[UNINSTALL] State directory removed" >> "$LOGFILE"

# Clear property overrides
resetprop -d sys.usb_dac_volume.initialized 2>/dev/null || true
resetprop -d sys.usb_dac_volume.framework 2>/dev/null || true
resetprop -d sys.usb_dac_volume.service_version 2>/dev/null || true

echo "[UNINSTALL] Properties reset" >> "$LOGFILE"

# ============================================================================
# AUDIO SERVICE RESTART FOR ORIGINAL BEHAVIOR
# ============================================================================

# Allow audio services to reload original vendor configuration
sleep 3

# Gracefully restart audio services
stop audioserver 2>/dev/null || true
sleep 2
start audioserver 2>/dev/null || true

stop android.hardware.audio.service 2>/dev/null || true
sleep 1
start android.hardware.audio.service 2>/dev/null || true

echo "[UNINSTALL] Audio services restarted" >> "$LOGFILE"
echo "[UNINSTALL] Module removal completed successfully" >> "$LOGFILE"

exit 0
