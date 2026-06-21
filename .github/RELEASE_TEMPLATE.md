---
name: USB-C DAC Volume Control Fix Release
about: Release notes template
---

## What's New in this Release

[Add release highlights and improvements here]

## Installation

### Easy Method (Recommended)
1. Download the ZIP file below
2. Open Magisk Manager
3. Tap **Modules** → **Install from storage**
4. Select the ZIP file
5. Reboot

### Terminal Method
```bash
adb shell su -c "magisk module install usb_dac_volume_control_v14.0.zip"
adb reboot
```

## Verification

```bash
# Check if module initialized
adb shell getprop sys.usb_dac_volume.initialized
# Expected: 1

# Check version
adb shell getprop sys.usb_dac_volume.service_version
```

## What This Module Does

✅ Fixes USB-C DAC volume control with system volume buttons  
✅ Auto-detects audio framework (AIDL/HIDL)  
✅ Integrates with V4A (ViPER4Android)  
✅ Integrates with JDSP/Dolby  
✅ Works on Android 10-14  
✅ Safe to uninstall (no side effects)  

## Files in This Release

- `usb_dac_volume_control_v14.0.zip` - Ready-to-install module
- `usb_dac_volume_control_v14.0.zip.sha256` - Integrity checksum

## Verify Integrity

```bash
sha256sum -c usb_dac_volume_control_v14.0.zip.sha256
```

## Troubleshooting

### Volume still doesn't work?

**Step 1:** Verify module installed
```bash
adb shell getprop sys.usb_dac_volume.initialized
# Should output: 1
```

**Step 2:** Check logs
```bash
adb shell cat /data/adb/usb_dac_volume.log | tail -50
```

**Step 3:** Verify properties
```bash
adb shell getprop audio.safemedia.force
# Should output: true

adb shell getprop audio.offload.disable
# Should output: 1
```

For more help, see [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

## Documentation

- **Quick Help:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Complete Guide:** [README.md](README.md)
- **Version History:** [CHANGELOG.md](CHANGELOG.md)

## Module Information

- **Minimum Magisk:** 24.0
- **Minimum Android:** 10 (API 29)
- **Supported Versions:** Android 10-14
- **Safe to Uninstall:** Yes

---

**Questions or issues?** Check the logs at `/data/adb/usb_dac_volume.log` or review the documentation files.
