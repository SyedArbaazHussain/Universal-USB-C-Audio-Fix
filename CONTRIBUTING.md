# Contributing to USB-C DAC Volume Control Fix

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. **Create** a feature branch for your changes
4. **Make** your changes
5. **Test** thoroughly
6. **Commit** with clear messages
7. **Push** to your fork
8. **Create** a Pull Request

## Code Guidelines

### Shell Scripts
- Use `/system/bin/sh` shebang
- Include descriptive comments for complex logic
- Add error handling for file operations
- Use meaningful variable names
- Test on multiple Android versions

### Properties
- Follow `key=value` syntax
- Include comments explaining purpose
- Avoid device-specific properties
- Use generic approach for maximum compatibility

### Documentation
- Keep it clear and concise
- Include examples where helpful
- Update version numbers in relevant places
- Test links and commands

## Testing Requirements

Before submitting a PR, test:

- [ ] Fresh installation on multiple devices
- [ ] Module initialization (check logs)
- [ ] Property application (getprop commands)
- [ ] Volume button functionality
- [ ] V4A integration (if applicable)
- [ ] JDSP integration (if applicable)
- [ ] Uninstallation and cleanup
- [ ] No boot loops or audio issues

## Commit Message Format

```
[TYPE] Brief description of change

Longer explanation if needed. Include:
- What changed and why
- Any side effects or dependencies
- Testing performed
- Fixes #123 (if applicable)
```

Types: `feat:` `fix:` `docs:` `refactor:` `test:` `chore:`

Example:
```
fix: Remove conflicting audio offload flag combinations

- Handle multiple flag combinations in sed replacements
- Add fallback for missing configuration files
- Tested on Android 12 and 13
- Fixes #42
```

## Pull Request Process

1. **Update** version numbers in module.prop if applicable
2. **Update** CHANGELOG.md with your changes
3. **Test** thoroughly on multiple devices
4. **Describe** what your PR does
5. **Reference** any related issues
6. **Be patient** - reviews take time

## Reporting Issues

When reporting a bug, include:

- Device model and Android version
- ROM name and build date
- Magisk version
- Full log from `/data/adb/usb_dac_volume.log`
- Steps to reproduce
- Expected vs actual behavior

## Feature Requests

When requesting a feature:

- Explain the use case
- Describe how it should work
- Consider alternatives
- Keep scope reasonable

## Code Review Process

All PRs go through code review:
1. Automated checks run (linting, etc)
2. Manual review by maintainers
3. Feedback provided if needed
4. Approval and merge

## Development Setup

### Local Building

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/Universal-USB-C-Audio-Fix.git
cd Universal-USB-C-Audio-Fix

# Make changes to files

# Build release package
chmod +x build_release.sh
./build_release.sh

# Result: usb_dac_volume_control_v14.0.zip (ready to install)
```

### Testing Your Changes

```bash
# Install the module
adb shell su -c "magisk module install ./usb_dac_volume_control_v14.0.zip"
adb reboot

# Wait for boot, then verify
adb shell getprop sys.usb_dac_volume.initialized
# Should output: 1

# Check logs
adb shell cat /data/adb/usb_dac_volume.log
```

## Release Process (Maintainers)

To create a release:

```bash
# Update version in module.prop
vim module.prop
# Change: version=v14.1, versionCode=141

# Update CHANGELOG
vim CHANGELOG.md

# Test the release
./build_release.sh

# Create git tag
git add .
git commit -m "Release v14.1"
git tag v14.1
git push origin main
git push origin v14.1

# GitHub Actions will automatically:
# 1. Build the ZIP
# 2. Generate SHA256
# 3. Create Release
# 4. Upload files
```

## Code of Conduct

- Be respectful and professional
- Provide constructive feedback
- Accept feedback gracefully
- Focus on the code, not the person
- Help others learn and improve

## Questions?

- Check existing [issues](../../issues)
- Review [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- Read [README.md](README.md)
- Ask in your PR description

## Areas for Contribution

We welcome help with:

- **Bug fixes** - Issues marked with `bug` label
- **Documentation** - Improving guides and examples
- **Testing** - Testing on different devices/ROMs
- **Features** - Improvements marked with `enhancement`
- **Localization** - Translating documentation

## License

By contributing, you agree that your contributions will be licensed under the GPL v3 License.

---

Thank you for helping improve USB-C DAC Volume Control Fix! 🎉
