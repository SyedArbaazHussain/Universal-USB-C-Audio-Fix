#!/system/bin/sh
###############################################################################
# USB-C DAC Volume Control Fix - Audio Device Detection & Verification
# Version: 14.0
# Purpose: Runtime audio device scanning and volume routing verification
# Usage: Can be called manually for debugging or integrated with service.sh
###############################################################################

LOGFILE="/data/adb/usb_dac_volume.log"

log_info() {
    echo "[AUDIO_CHECK] $1" >> "$LOGFILE"
    echo "$1"
}

log_success() {
    echo "[AUDIO_CHECK_OK] $1" >> "$LOGFILE"
    echo "[✓] $1"
}

log_error() {
    echo "[AUDIO_CHECK_ERROR] $1" >> "$LOGFILE"
    echo "[✗] $1"
}

# ============================================================================
# AUDIO DEVICE ENUMERATION
# ============================================================================

log_info "===== Audio Device Enumeration ====="

# Check for sound class devices
if [ -d "/sys/class/sound" ]; then
    log_info "Scanning /sys/class/sound..."
    
    PCMCOUNT=0
    USBCOUNT=0
    
    for device in /sys/class/sound/*; do
        devname=$(basename "$device")
        
        if [ -f "$device/uevent" ]; then
            # Check if USB device
            if grep -q "usb" "$device/uevent" 2>/dev/null; then
                USBCOUNT=$((USBCOUNT + 1))
                log_success "USB Audio Device: $devname"
            fi
            
            # Count PCM devices
            if echo "$devname" | grep -q "pcm"; then
                PCMCOUNT=$((PCMCOUNT + 1))
            fi
        fi
    done
    
    log_info "PCM devices found: $PCMCOUNT"
    log_info "USB audio devices found: $USBCOUNT"
else
    log_error "Sound class directory not found"
fi

# ============================================================================
# AUDIO DEVICE CHARACTERISTICS
# ============================================================================

log_info "===== Audio Device Characteristics ====="

# Check for USB audio class devices
if [ -d "/sys/bus/usb/devices" ]; then
    USB_AUDIO_DEVICES=0
    
    for device in /sys/bus/usb/devices/*/; do
        if [ -f "$device/bDeviceClass" ]; then
            DEVCLASS=$(cat "$device/bDeviceClass" 2>/dev/null)
            # Class 01 = Audio Interface, FF = Vendor specific
            if [ "$DEVCLASS" = "01" ] || [ "$DEVCLASS" = "ff" ]; then
                USB_AUDIO_DEVICES=$((USB_AUDIO_DEVICES + 1))
                MANUFACTURER=$(cat "$device/manufacturer" 2>/dev/null || echo "Unknown")
                PRODUCT=$(cat "$device/product" 2>/dev/null || echo "Unknown")
                log_success "Audio Device: $MANUFACTURER $PRODUCT"
            fi
        fi
    done
    
    log_info "USB audio class devices: $USB_AUDIO_DEVICES"
fi

# ============================================================================
# AUDIO SERVICE STATUS
# ============================================================================

log_info "===== Audio Service Status ====="

# Check audioserver
if pgrep -x "audioserver" > /dev/null 2>&1; then
    log_success "audioserver is running"
    AUDIOSERVER_PID=$(pgrep -x "audioserver" | head -1)
    log_info "audioserver PID: $AUDIOSERVER_PID"
else
    log_error "audioserver is NOT running"
fi

# Check AIDL audio service
if pgrep -x "android.hardware.audio" > /dev/null 2>&1; then
    log_success "android.hardware.audio.service is running"
    AIDLSERVICE_PID=$(pgrep -x "android.hardware.audio" | head -1)
    log_info "AIDL service PID: $AIDLSERVICE_PID"
else
    log_info "AIDL audio service not detected (possible HIDL only)"
fi

# ============================================================================
# AUDIO FRAMEWORK PROPERTIES
# ============================================================================

log_info "===== Audio Framework Properties ====="

PROPERTIES=(
    "audio.safemedia.force"
    "ro.audio.flinger_infidelity_bypass"
    "persist.vendor.audio.aidl.offload.enable"
    "audio.offload.disable"
    "ro.bluetooth.volume.hw_sync"
    "ro.audio.usb.routing"
    "persist.audio.usb.routing"
    "sys.usb_dac_volume.initialized"
    "sys.usb_dac_volume.framework"
)

for prop in "${PROPERTIES[@]}"; do
    value=$(getprop "$prop" 2>/dev/null || echo "not set")
    log_info "$prop = $value"
done

# ============================================================================
# AUDIO POLICY CONFIGURATION
# ============================================================================

log_info "===== Audio Policy Configuration ====="

# Check for patched audio policy configurations
PATCHED_CONFIGS=""

for config_path in \
    "/vendor/etc/audio_policy_configuration.xml" \
    "/system/etc/audio_policy_configuration.xml" \
    "/vendor/etc/audio/audio_policy_configuration.xml" \
    "/system/etc/audio/audio_policy_configuration.xml"; do
    
    if [ -f "$config_path" ]; then
        if grep -q "AUDIO_OUTPUT_FLAG_DIRECT" "$config_path" 2>/dev/null; then
            log_error "Config has DIRECT flag: $config_path"
        else
            log_success "Config is patched (no DIRECT flag): $config_path"
        fi
    fi
done

# ============================================================================
# VOLUME CONTROL ROUTING VERIFICATION
# ============================================================================

log_info "===== Volume Control Routing Verification ====="

# Check if software mixer is available
if [ -d "/proc/asound/card0" ]; then
    log_success "Software mixer interface available"
    
    if [ -f "/proc/asound/card0/mixer" ]; then
        MIXER_CONTROLS=$(cat /proc/asound/card0/mixer 2>/dev/null | wc -l)
        log_info "Mixer controls available: $MIXER_CONTROLS"
    fi
else
    log_error "Software mixer not found"
fi

# Check for hardware offload indicators
OFFLOAD_INDICATOR=0
for device in /sys/class/sound/pcm*/; do
    if [ -f "$device/dev" ]; then
        # Attempt to read device capabilities
        OFFLOAD_INDICATOR=$((OFFLOAD_INDICATOR + 1))
    fi
done

log_info "PCM output devices detected: $OFFLOAD_INDICATOR"

# ============================================================================
# MODULE STATE VERIFICATION
# ============================================================================

log_info "===== Module State ====="

if [ -d "/data/adb/usb_dac_volume_state" ]; then
    log_success "Module state directory exists"
    STATE_FILES=$(ls -la /data/adb/usb_dac_volume_state/ 2>/dev/null | wc -l)
    log_info "State files: $STATE_FILES"
else
    log_error "Module state directory not found"
fi

# Check for detection flags
if [ -f "/data/adb/modules/usb_dac_volume_control/.viper4android_detected" ]; then
    log_success "V4A module detected and configured"
fi

if [ -f "/data/adb/modules/usb_dac_volume_control/.jdsp_detected" ]; then
    log_success "JDSP module detected and configured"
fi

# ============================================================================
# FINAL SUMMARY
# ============================================================================

log_info "===== Audio System Summary ====="

MODULE_INITIALIZED=$(getprop sys.usb_dac_volume.initialized 2>/dev/null || echo "0")
MODULE_FRAMEWORK=$(getprop sys.usb_dac_volume.framework 2>/dev/null || echo "unknown")

if [ "$MODULE_INITIALIZED" = "1" ]; then
    log_success "Module is INITIALIZED and ACTIVE"
    log_info "Detected framework: $MODULE_FRAMEWORK"
else
    log_error "Module is NOT initialized"
fi

log_info "===== Audio Device Check Complete ====="

exit 0
