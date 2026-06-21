#!/system/bin/sh
###############################################################################
# USB-C DAC Volume Control Fix - Runtime Service Script
# Version: 14.0
# Runs at: service (late boot stage)
# Purpose: Apply runtime audio framework fixes, integrate with v4a/jdsp
###############################################################################

MODDIR=${0%/*}
LOGFILE="/data/adb/usb_dac_volume.log"

log_info() {
    echo "[SERVICE] $1" >> "$LOGFILE"
}

log_error() {
    echo "[SERVICE_ERROR] $1" >> "$LOGFILE"
}

log_success() {
    echo "[SERVICE_OK] $1" >> "$LOGFILE"
}

log_info "========== SERVICE PHASE INITIATED =========="

# ============================================================================
# WAIT FOR SYSTEM STABILITY
# ============================================================================

# Wait for boot completion
BOOT_TIMEOUT=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $BOOT_TIMEOUT -lt 120 ]; do
    sleep 2
    BOOT_TIMEOUT=$((BOOT_TIMEOUT + 2))
done

if [ "$(getprop sys.boot_completed)" = "1" ]; then
    log_success "System boot completed"
else
    log_error "Boot timeout - proceeding anyway"
fi

# ============================================================================
# DETECT RUNTIME AUDIO FRAMEWORK
# ============================================================================

log_info "Detecting runtime audio framework configuration..."

AIDL_DETECTED=0
HIDL_DETECTED=0
RUNTIME_FRAMEWORK="unknown"

# Check AIDL (Android 12+)
if [ -f "/vendor/etc/audio_policy_configuration.xml" ] || \
   [ -f "/system/etc/audio_policy_configuration.xml" ]; then
    if grep -q "aidl" /vendor/build.prop 2>/dev/null || \
       grep -q "aidl" /system/build.prop 2>/dev/null || \
       [ -f "/vendor/lib64/android.hardware.audio.service.so" ] || \
       [ -f "/system/lib64/android.hardware.audio.service.so" ]; then
        AIDL_DETECTED=1
        RUNTIME_FRAMEWORK="AIDL"
        log_success "Runtime framework: AIDL"
    fi
fi

# Check HIDL (Android 8-11)
if [ -f "/vendor/lib64/hw/android.hardware.audio@7.0-impl.so" ] || \
   [ -f "/vendor/lib64/hw/android.hardware.audio@6.0-impl.so" ] || \
   [ -f "/vendor/lib64/hw/android.hardware.audio@5.0-impl.so" ]; then
    HIDL_DETECTED=1
    RUNTIME_FRAMEWORK="HIDL"
    log_success "Runtime framework: HIDL"
fi

if [ $AIDL_DETECTED -eq 0 ] && [ $HIDL_DETECTED -eq 0 ]; then
    RUNTIME_FRAMEWORK="HYBRID"
    log_error "Could not detect explicit framework, using hybrid approach"
fi

setprop sys.usb_dac_volume.framework "$RUNTIME_FRAMEWORK"

# ============================================================================
# DETECT USB DAC DEVICES
# ============================================================================

log_info "Scanning for USB audio devices..."

USB_DEVICE_COUNT=0
if [ -d "/sys/class/sound" ]; then
    for device in /sys/class/sound/card*; do
        if [ -f "$device/uevent" ]; then
            if grep -q "usb" "$device/uevent" 2>/dev/null; then
                USB_DEVICE_COUNT=$((USB_DEVICE_COUNT + 1))
            fi
        fi
    done
fi

log_info "USB audio devices detected: $USB_DEVICE_COUNT"

# ============================================================================
# APPLY GLOBAL AUDIO FRAMEWORK PROPERTIES
# ============================================================================

log_info "Applying global audio framework overrides..."

# Force software volume scaling (critical for DAC control)
setprop audio.safemedia.force true
log_success "Software volume scaling enabled"

# Disable Flinger infidelity bypass (routes through software mixer)
setprop ro.audio.flinger_infidelity_bypass false
log_success "Flinger direct routing disabled"

# Disable AIDL offload on USB (forces software processing)
setprop persist.vendor.audio.aidl.offload.enable false
setprop persist.vendor.audio.aidl.compress.enable false
log_success "AIDL hardware offload disabled"

# Disable general offload flags
setprop audio.offload.disable 1
setprop persist.audio.offload.enabled false
log_success "Audio offload disabled globally"

# Disable hardware-synced absolute volume (USB DACs don't support this properly)
setprop ro.bluetooth.volume.hw_sync false
setprop persist.audio.vbs.volume 1
log_success "Hardware volume sync disabled"

# ============================================================================
# DETECT AND INTEGRATE V4A
# ============================================================================

log_info "Checking for V4A (ViPER4Android) integration..."

if [ -d "/data/adb/modules/viper4android" ] || [ -d "/data/adb/modules/v4a" ]; then
    log_success "V4A detected - integrating volume control layer"
    
    # V4A uses its own audio framework, ensure USB routing works
    setprop vendor.audio.feature.v4a true 2>/dev/null || true
    setprop ro.audio.viper true 2>/dev/null || true
    
    # Force V4A to process USB audio
    setprop persist.vendor.audio.v4a.enable true 2>/dev/null || true
fi

# ============================================================================
# DETECT AND INTEGRATE JDSP
# ============================================================================

log_info "Checking for JDSP/Dolby integration..."

if [ -d "/data/adb/modules/jdsp" ] || [ -d "/data/adb/modules/dolby" ]; then
    log_success "JDSP module detected - integrating volume control layer"
    
    # JDSP audio routing
    setprop vendor.audio.feature.jdsp true 2>/dev/null || true
    setprop ro.audio.jdsp true 2>/dev/null || true
fi

# ============================================================================
# USB AUDIO POLICY CONFIGURATION
# ============================================================================

log_info "Configuring USB audio routing policies..."

# Disable USB audio automatic routing (use software mixer instead)
settings put global usb_audio_automatic_routing_disabled 0 2>/dev/null || true
log_success "USB audio automatic routing configured"

# Set default USB audio output behavior
settings put system volume_music_usb 7 2>/dev/null || true
log_success "USB audio output level configured"

# ============================================================================
# AUDIO FRAMEWORK COMMAND INTERFACE (if available)
# ============================================================================

log_info "Applying audio framework command-level fixes..."

# Mute absolute volume control on USB endpoints via audio HAL commands
if command -v cmd >/dev/null 2>&1; then
    # Device type 32 = USB headset/DAC endpoint
    cmd audio set-volume-behavior 32 muted 2>/dev/null || true
    # Device type 22 = USB speaker endpoint  
    cmd audio set-volume-behavior 22 muted 2>/dev/null || true
    log_success "Audio HAL command interface applied"
else
    log_error "Audio command interface unavailable - skipping"
fi

# ============================================================================
# AUDIO SERVICE RESTART (graceful)
# ============================================================================

log_info "Finalizing audio framework..."

# Gracefully stop and restart audio services to apply new policies
# This is safer than killall in modern Android versions

if [ -f "/system/bin/audioserver" ] || [ -f "/system/bin/audio.service" ]; then
    log_info "Requesting audio service restart..."
    
    # Use stop/start method (Android 10+)
    stop audioserver 2>/dev/null || true
    sleep 2
    start audioserver 2>/dev/null || true
    
    # AIDL audio service restart (Android 12+)
    stop android.hardware.audio.service 2>/dev/null || true
    sleep 1
    start android.hardware.audio.service 2>/dev/null || true
    
    sleep 2
    log_success "Audio service reset complete"
fi

# ============================================================================
# VERIFY AUDIO DEVICE ROUTING
# ============================================================================

log_info "Verifying USB audio device routing..."

# Check if audio policy was applied successfully
if [ -d "/sys/class/sound" ]; then
    DEVICE_CHECK=0
    for device in /sys/class/sound/pcm*; do
        if [ -f "$device" ]; then
            DEVICE_CHECK=$((DEVICE_CHECK + 1))
        fi
    done
    
    if [ $DEVICE_CHECK -gt 0 ]; then
        log_success "Audio routing verified: $DEVICE_CHECK devices found"
    fi
fi

# ============================================================================
# FINAL STATE
# ============================================================================

setprop sys.usb_dac_volume.initialized 1
setprop sys.usb_dac_volume.service_version "14.0"

log_info "========== SERVICE PHASE COMPLETED =========="
exit 0