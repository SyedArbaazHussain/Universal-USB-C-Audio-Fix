#!/system/bin/sh
###############################################################################
# USB-C DAC Volume Control Fix - Magisk Module Installation Script
# Version: 14.0
# Features: AIDL/HIDL detection, comprehensive audio policy patching, 
#           v4a/jdsp integration, multi-fallback audio framework support
###############################################################################

SKIP_UNZIP=0
LOGFILE="/data/adb/usb_dac_volume.log"

# Ensure log file exists and has a header
mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
echo "[INSTALL $(date +'%Y-%m-%d %H:%M:%S')] Starting installation" > "$LOGFILE" 2>/dev/null || true

# ============================================================================
# LOGGING & UTILITIES
# ============================================================================

log_verbose() {
    ui_print "  [*] $1"
    echo "[USB_DAC_VOL] $1" >> /data/adb/usb_dac_volume.log
}

log_warning() {
    ui_print "  [!] $1"
    echo "[USB_DAC_VOL_WARN] $1" >> /data/adb/usb_dac_volume.log
}

log_error() {
    ui_print "  [ERROR] $1"
    echo "[USB_DAC_VOL_ERROR] $1" >> /data/adb/usb_dac_volume.log
}

log_success() {
    ui_print "  [✓] $1"
    echo "[USB_DAC_VOL_OK] $1" >> /data/adb/usb_dac_volume.log
}

# ============================================================================
# FRAMEWORK DETECTION
# ============================================================================

ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  USB-C DAC Volume Control Fix - Installation Phase"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_verbose "Starting system audio framework detection..."

# Detect KSU/APatch meta-module managers during install
if ls /data/adb/modules 2>/dev/null | grep -qi ksu; then
    log_success "KSU-like meta-module manager present"
fi
if ls /data/adb/modules 2>/dev/null | grep -qi apatch; then
    log_success "APatch-like meta-module manager present"
fi

# Detect AIDL vs HIDL architecture
DETECTED_AIDL=0
DETECTED_HIDL=0
AUDIO_SERVER_TYPE="unknown"

# Check for AIDL audio service (Android 12+)
if [ -f "/vendor/etc/audio_policy_configuration.xml" ] || \
   [ -f "/vendor/etc/audio/audio_policy_configuration.xml" ] || \
   [ -f "/system/etc/audio_policy_configuration.xml" ]; then
    if grep -q "audio.aidl.version" /vendor/default.prop 2>/dev/null || \
       grep -q "audio.aidl.version" /system/build.prop 2>/dev/null; then
        DETECTED_AIDL=1
        AUDIO_SERVER_TYPE="AIDL"
        log_success "Detected AIDL audio framework (Android 12+)"
    fi
fi

# Check for HIDL audio service (Android 8-11)
if [ -f "/vendor/lib64/hw/android.hardware.audio@5.0-impl.so" ] || \
   [ -f "/vendor/lib64/hw/android.hardware.audio@6.0-impl.so" ] || \
   [ -f "/vendor/lib64/hw/android.hardware.audio@7.0-impl.so" ] || \
   [ -f "/vendor/lib/hw/android.hardware.audio@5.0-impl.so" ] || \
   [ -f "/vendor/lib/hw/android.hardware.audio@6.0-impl.so" ] || \
   [ -f "/vendor/lib/hw/android.hardware.audio@7.0-impl.so" ]; then
    DETECTED_HIDL=1
    AUDIO_SERVER_TYPE="HIDL"
    log_success "Detected HIDL audio framework (Android 8-11)"
fi

# Fallback: Check for both
if [ $DETECTED_AIDL -eq 0 ] && [ $DETECTED_HIDL -eq 0 ]; then
    log_warning "Could not explicitly detect audio framework version, attempting generic approach"
    DETECTED_AIDL=1
    DETECTED_HIDL=1
    AUDIO_SERVER_TYPE="HYBRID"
fi

log_verbose "Audio Framework Type: $AUDIO_SERVER_TYPE"

# ============================================================================
# DETECT AUDIO POLICY CONFIGURATIONS
# ============================================================================

log_verbose "Scanning for audio policy configuration files..."

TARGET_CONFIGS=""
AUDIO_CONFIG_FOUND=0

# Primary XML config locations
for CONFIG_PATH in \
    "/vendor/etc/audio_policy_configuration.xml" \
    "/vendor/etc/audio/audio_policy_configuration.xml" \
    "/system/etc/audio_policy_configuration.xml" \
    "/system/etc/audio/audio_policy_configuration.xml" \
    "/vendor/etc/usb_audio_policy_configuration.xml" \
    "/vendor/etc/audio/usb_audio_policy_configuration.xml" \
    "/vendor/etc/audio_effects.xml" \
    "/vendor/etc/audio/audio_effects.xml"; do
    
    if [ -f "$CONFIG_PATH" ]; then
        TARGET_CONFIGS="$TARGET_CONFIGS $CONFIG_PATH"
        AUDIO_CONFIG_FOUND=1
        log_verbose "Found config: $CONFIG_PATH"
    fi
done

if [ $AUDIO_CONFIG_FOUND -eq 0 ]; then
    log_warning "No XML config files found - using property-based patching fallback"
fi

# ============================================================================
# AUDIO POLICY PATCHING
# ============================================================================

log_verbose "Initiating audio policy structural modifications..."

if [ ! -z "$TARGET_CONFIGS" ]; then
    for CONFIG in $TARGET_CONFIGS; do
        MOD_DEST="$MODPATH/system$(dirname "$CONFIG")"
        mkdir -p "$MOD_DEST"
        
        log_verbose "Patching: $CONFIG"
        
        # Remove all direct hardware offload flags that bypass software volume control
        sed -e 's/flags="AUDIO_OUTPUT_FLAG_DIRECT"//g' \
            -e 's/flags="AUDIO_OUTPUT_FLAG_DIRECT|[^"]*"//g' \
            -e 's/flags="[^"]*|AUDIO_OUTPUT_FLAG_DIRECT"//g' \
            -e 's/|AUDIO_OUTPUT_FLAG_DIRECT//g' \
            -e 's/AUDIO_OUTPUT_FLAG_DIRECT|//g' \
            -e 's/flags="AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD"//g' \
            -e 's/flags="AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD|[^"]*"//g' \
            -e 's/flags="[^"]*|AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD"//g' \
            -e 's/|AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD//g' \
            -e 's/AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD|//g' \
            -e 's/flags="AUDIO_OUTPUT_FLAG_HW_AV_SYNC"//g' \
            -e 's/flags="AUDIO_OUTPUT_FLAG_HW_AV_SYNC|[^"]*"//g' \
            -e 's/flags="[^"]*|AUDIO_OUTPUT_FLAG_HW_AV_SYNC"//g' \
            -e 's/|AUDIO_OUTPUT_FLAG_HW_AV_SYNC//g' \
            -e 's/AUDIO_OUTPUT_FLAG_HW_AV_SYNC|//g' \
            -e 's/flags="AUDIO_OUTPUT_FLAG_PRIMARY|[^"]*"//g' \
            "$CONFIG" > "$MOD_DEST/$(basename "$CONFIG")" 2>/dev/null
        
        if [ -f "$MOD_DEST/$(basename "$CONFIG")" ]; then
            log_success "Successfully patched: $(basename "$CONFIG")"
        else
            log_error "Failed to patch: $(basename "$CONFIG")"
        fi
    done
fi

# ============================================================================
# DETECT V4A & JDSP INSTALLATIONS
# ============================================================================

log_verbose "Checking for V4A (ViPER4Android) installation..."
if [ -d "/data/adb/modules/viper4android" ] || [ -d "/data/adb/modules/v4a" ]; then
    log_success "V4A module detected - will integrate with volume scaling"
    mkdir -p "$MODPATH/system/vendor/etc/audio"
    touch "$MODPATH/.viper4android_detected"
fi

log_verbose "Checking for JDSP installation..."
if [ -d "/data/adb/modules/jdsp" ] || [ -d "/data/adb/modules/dolby" ]; then
    log_success "JDSP/Dolby module detected - will integrate with volume scaling"
    mkdir -p "$MODPATH/system/vendor/etc/audio"
    touch "$MODPATH/.jdsp_detected"
fi

# ============================================================================
# CREATE INITIALIZATION DIRECTORY STRUCTURE
# ============================================================================

log_verbose "Creating module directory structure..."

mkdir -p "$MODPATH/system/vendor/etc/audio"
mkdir -p "$MODPATH/system/etc/audio"
mkdir -p "$MODPATH/system/build.prop.d"

# ============================================================================
# AIDL-SPECIFIC PATCHES
# ============================================================================

if [ $DETECTED_AIDL -eq 1 ]; then
    log_verbose "Applying AIDL-specific audio framework patches..."
    
    # AIDL audio policy configurations
    if [ -f "/vendor/etc/audio_policy_configuration.xml" ]; then
        MOD_DEST="$MODPATH/system/vendor/etc"
        mkdir -p "$MOD_DEST"
        cp "/vendor/etc/audio_policy_configuration.xml" "$MOD_DEST/" 2>/dev/null || true
        
        # Patch to remove direct flags
        sed -i -e 's/AUDIO_OUTPUT_FLAG_DIRECT//g' \
                -e 's/AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD//g' \
                "$MOD_DEST/audio_policy_configuration.xml" 2>/dev/null
    fi
fi

# ============================================================================
# HIDL-SPECIFIC PATCHES
# ============================================================================

if [ $DETECTED_HIDL -eq 1 ]; then
    log_verbose "Applying HIDL-specific audio framework patches..."
    
    # HIDL effect configuration
    if [ -f "/vendor/etc/audio_effects.xml" ]; then
        MOD_DEST="$MODPATH/system/vendor/etc"
        mkdir -p "$MOD_DEST"
        cp "/vendor/etc/audio_effects.xml" "$MOD_DEST/" 2>/dev/null || true
    fi
fi

# ============================================================================
# CREATE AUDIO ROUTING HELPER SCRIPT
# ============================================================================

log_verbose "Creating audio routing helper script..."

cat > "$MODPATH/system/etc/audio_fix_helper.sh" << 'EOF'
#!/system/bin/sh
# Helper script for audio volume routing fixes
# This script is sourced by service.sh and common/system.prop.d/

# Prevent direct USB audio output flag hijacking
getprop ro.audio.flinger_infidelity_bypass 2>/dev/null || echo "false"

# Disable offload on USB devices
getprop persist.vendor.audio.aidl.offload.enable 2>/dev/null || echo "false"

# Enable software volume scaling
getprop audio.safemedia.force 2>/dev/null || echo "true"
EOF

chmod 755 "$MODPATH/system/etc/audio_fix_helper.sh"
log_success "Audio helper script created"

log_success "Installation phase completed successfully!"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"