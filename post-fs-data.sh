#!/system/bin/sh
###############################################################################
# USB-C DAC Volume Control Fix - Early Boot Phase
# Version: 14.0
# Runs at: post-fs-data (earliest possible moment)
# Purpose: Initialize audio framework hooks before audio service starts
###############################################################################

MODDIR=${0%/*}
LOGFILE="/data/adb/usb_dac_volume.log"

log_info() {
    echo "[POST_FS_DATA] $1" >> "$LOGFILE"
}

log_info "========== EARLY BOOT PHASE INITIATED =========="

# ============================================================================
# WAIT FOR FILESYSTEM STABILITY
# ============================================================================

while [ ! -d "/data/adb" ]; do
    sleep 1
done

# ============================================================================
# INITIALIZE MODULE STATE
# ============================================================================

# Create state directory
mkdir -p /data/adb/usb_dac_volume_state
chmod 777 /data/adb/usb_dac_volume_state

# Initialize logging
: > "$LOGFILE"
chmod 666 "$LOGFILE"

log_info "Audio framework state initialization complete"

# ============================================================================
# PREPARE AUDIO POLICY OVERLAYS
# ============================================================================

# Ensure patched configs are accessible
if [ -d "$MODDIR/system/vendor/etc" ]; then
    log_info "Verified patched vendor audio configs present"
fi

if [ -d "$MODDIR/system/system/etc" ]; then
    log_info "Verified patched system audio configs present"
fi

# ============================================================================
# PRE-LOAD AUDIO FRAMEWORK PROPERTIES
# ============================================================================

# Set initial property overrides (will be finalized in service.sh)
setprop sys.usb_dac_volume.initialized 0
setprop sys.usb_dac_volume.framework "pending"

log_info "Early boot phase completed successfully"
exit 0
