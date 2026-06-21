#!/bin/bash
###############################################################################
# USB-C DAC Volume Control Fix - Release Build Script
# Version: 1.0
# Purpose: Package module for release distribution
###############################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}USB-C DAC Volume Control Fix - Release Build${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get version from module.prop
VERSION=$(grep '^version=' module.prop | cut -d'=' -f2)
VERSION_CODE=$(grep '^versionCode=' module.prop | cut -d'=' -f2)

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Could not extract version from module.prop${NC}"
    exit 1
fi

echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Version Code: ${VERSION_CODE}${NC}"

# Define output file
ZIP_NAME="usb_dac_volume_control_${VERSION}.zip"

# Clean previous builds
if [ -d "build" ]; then
    echo -e "${YELLOW}Cleaning previous build...${NC}"
    rm -rf build
fi

if [ -f "$ZIP_NAME" ]; then
    echo -e "${YELLOW}Removing old ZIP file...${NC}"
    rm -f "$ZIP_NAME"
fi

if [ -f "$ZIP_NAME.sha256" ]; then
    rm -f "$ZIP_NAME.sha256"
fi

# Create build directory
echo -e "${YELLOW}Creating build directory...${NC}"
mkdir -p build

# Copy core module files
echo -e "${YELLOW}Copying module files...${NC}"
cp module.prop build/
cp customize.sh build/
cp post-fs-data.sh build/
cp service.sh build/
cp uninstall.sh build/
cp system.prop build/

# Copy utility script
cp check_audio_devices.sh build/

# Create directory structure for properties fallback
echo -e "${YELLOW}Setting up directory structure...${NC}"
mkdir -p build/common/system/build.prop.d
cp common/system/build.prop.d/audio.prop build/common/system/build.prop.d/

# Set executable permissions
echo -e "${YELLOW}Setting file permissions...${NC}"
chmod 755 build/customize.sh
chmod 755 build/post-fs-data.sh
chmod 755 build/service.sh
chmod 755 build/uninstall.sh
chmod 755 build/check_audio_devices.sh
chmod 644 build/module.prop
chmod 644 build/system.prop
chmod 644 build/common/system/build.prop.d/audio.prop

# Create ZIP archive
echo -e "${YELLOW}Creating ZIP archive: ${ZIP_NAME}${NC}"
cd build
zip -r "../${ZIP_NAME}" . -q -x "*.git*" "*.github*" "*.DS_Store"
cd ..

# Verify ZIP contents
echo -e "${YELLOW}Verifying ZIP contents...${NC}"
unzip -l "$ZIP_NAME" > /dev/null || {
    echo -e "${RED}Error: ZIP file verification failed${NC}"
    exit 1
}

# Generate SHA256 checksum
echo -e "${YELLOW}Generating SHA256 checksum...${NC}"
sha256sum "$ZIP_NAME" > "$ZIP_NAME.sha256"

# Display results
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}Output Files:${NC}"
echo -e "  📦 ${ZIP_NAME}"
echo -e "  ✓  $(ls -lh "$ZIP_NAME" | awk '{print $5}')"
echo ""
echo -e "  🔐 ${ZIP_NAME}.sha256"
echo -e "  ✓  Checksum: $(cat "$ZIP_NAME.sha256" | awk '{print $1}' | cut -c1-16)..."
echo ""

# Show verification command
echo -e "${GREEN}Verification:${NC}"
echo -e "  ${YELLOW}sha256sum -c ${ZIP_NAME}.sha256${NC}"
echo ""

# Show installation instructions
echo -e "${GREEN}Installation:${NC}"
echo -e "  1. Download ${ZIP_NAME}"
echo -e "  2. Open Magisk Manager"
echo -e "  3. Tap Modules → Install from storage"
echo -e "  4. Select the ZIP file"
echo -e "  5. Reboot"
echo ""

# Cleanup
echo -e "${YELLOW}Cleaning up build directory...${NC}"
rm -rf build

echo -e "${GREEN}Ready for release!${NC}"
echo ""

exit 0
