#!/system/bin/sh
# Wait for the system framework to stabilize
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Intercept and force device-independent framework streams to drop absolute volume controls
# Native system profile commands targeting standard USB digital device endpoints (Enum 32 / 22)
settings put global usb_audio_automatic_routing_disabled 0
settings put system volume_music_usb 7
cmd audio set-volume-behavior 32 muted 2>/dev/null
cmd audio set-volume-behavior 22 muted 2>/dev/null

# Safely pulse the media frameworks to apply active runtime parameters
killall android.hardware.audio.service 2>/dev/null
killall audioserver 2>/dev/null