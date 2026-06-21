---
name: Bug Report
about: Report an issue with the module
title: "[BUG] "
labels: bug
assignees: ''

---

## Description
<!-- Clear description of the issue -->

## Device Information
- **Device Model:** (e.g., Samsung Galaxy S21)
- **Android Version:** (e.g., Android 12)
- **ROM Name & Build:** (e.g., OneUI 4.1)
- **Magisk Version:** (e.g., 24.3)
- **Module Version:** (output: `adb shell getprop sys.usb_dac_volume.service_version`)

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior
<!-- What should happen -->

## Actual Behavior
<!-- What actually happens -->

## Logs
```
Paste the contents of /data/adb/usb_dac_volume.log here
```

## Debugging Information
```bash
# Run this and paste output:
adb shell getprop | grep -E "audio|usb|usb_dac"
```

## Additional Context
<!-- Any other relevant information -->

---

**Before submitting:**
- [ ] I've checked if this issue already exists
- [ ] I've read the QUICK_REFERENCE.md troubleshooting section
- [ ] I've included the full log file output
