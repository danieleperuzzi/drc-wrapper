#!/bin/bash
set -e

# Check if version argument is provided
if [ -z "$1" ]; then
  echo "Error: missing version argument." >&2
  echo "Usage: $0 <version>" >&2
  echo "Example: $0 1.0-1" >&2
  exit 1
fi

VERSION="$1"
PACKAGE_NAME="drcwrapper"
BUILD_DIR="build_staging"
FINAL_PKG_DIR="${PACKAGE_NAME}_${VERSION}_all"

echo "Building package ${PACKAGE_NAME} version ${VERSION}..."

# Clean up previous build artifacts
rm -rf "$BUILD_DIR" "${FINAL_PKG_DIR}.deb"

# Create staging directory structure
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"

# Process template files and inject version number
sed "s/__DEB_VERSION__/${VERSION}/g" DEBIAN/control.template > "$BUILD_DIR/DEBIAN/control"
cp DEBIAN/postinst.template "$BUILD_DIR/DEBIAN/postinst"
cp DEBIAN/postrm.template "$BUILD_DIR/DEBIAN/postrm"

# Copy main executable script from root repository directory
cp ./drcwrapper "$BUILD_DIR/usr/local/bin/drcwrapper"

# Set standard POSIX permissions
chmod 755 "$BUILD_DIR/DEBIAN/control"
chmod 755 "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/DEBIAN/postrm"
chmod 755 "$BUILD_DIR/usr/local/bin/drcwrapper"

# Build Debian package and enforce root owner/group for all files
dpkg-deb --root-owner-group --build "$BUILD_DIR" "${FINAL_PKG_DIR}.deb"

# Clean up temporary build staging directory
rm -rf "$BUILD_DIR"

echo "Package created successfully: ${FINAL_PKG_DIR}.deb"
