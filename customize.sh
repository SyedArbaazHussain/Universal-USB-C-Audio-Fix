#!/system/bin/sh
SKIP_UNZIP=0

ui_print "- Beginning Universal Audio Layer Structural Scans..."

# Track down where the active device isolates its policy parameters
TARGET_CONFIGS=""
[ -f "/vendor/etc/audio_policy_configuration.xml" ] && TARGET_CONFIGS="$TARGET_CONFIGS /vendor/etc/audio_policy_configuration.xml"
[ -f "/vendor/etc/audio/audio_policy_configuration.xml" ] && TARGET_CONFIGS="$TARGET_CONFIGS /vendor/etc/audio/audio_policy_configuration.xml"
[ -f "/vendor/etc/usb_audio_policy_configuration.xml" ] && TARGET_CONFIGS="$TARGET_CONFIGS /vendor/etc/usb_audio_policy_configuration.xml"
[ -f "/vendor/etc/audio/usb_audio_policy_configuration.xml" ] && TARGET_CONFIGS="$TARGET_CONFIGS /vendor/etc/audio/usb_audio_policy_configuration.xml"

if [ -z "$TARGET_CONFIGS" ]; then
    ui_print "- Warning: No explicit XML configuration paths caught. Relying on property overrides."
else
    for CONFIG in $TARGET_CONFIGS; do
        # Mirror the directory pathway dynamically inside the module structure
        MOD_DEST="$MODPATH/system$(dirname "$CONFIG")"
        mkdir -p "$MOD_DEST"
        
        ui_print "- Programmatically patching: $CONFIG"
        
        # Dynamically strip high-performance, raw direct-tunnel flags from the device's native XML layout
        # This forces the HAL to register USB devices under generic software streams natively
        sed -e 's/flags="AUDIO_OUTPUT_FLAG_DIRECT"//g' \
            -e 's/flags="AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD"//g' \
            -e 's/flags="AUDIO_OUTPUT_FLAG_HW_AV_SYNC"//g' \
            "$CONFIG" > "$MOD_DEST/$(basename "$CONFIG")"
    done
fi

ui_print "- Dynamic software engine hooks compiled successfully."