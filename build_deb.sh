#!/bin/bash
set -e

# Check if version argument is provided
if [ -z "$1" ]; then
  echo "Error: missing version argument." >&2
  echo "Usage: $0 <version>" >&2
  echo "Example: $0 1.0.0-1" >&2
  exit 1
fi

VERSION="$1"
PACKAGE_NAME="drc-wrapper"
BUILD_DIR="build_staging"
FINAL_PKG_DIR="${PACKAGE_NAME}_${VERSION}_all"

echo "Building package ${PACKAGE_NAME} version ${VERSION}..."

# Clean up previous build artifacts
rm -rf "$BUILD_DIR" "${FINAL_PKG_DIR}.deb"

# Create staging directory structure
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}"

# Process control template file and inject version number
sed "s/__DEB_VERSION__/${VERSION}/g" DEBIAN/control.template > "$BUILD_DIR/DEBIAN/control"
chmod 644 "$BUILD_DIR/DEBIAN/control"

# Copy postinst and postrm directly if present
if [ -f "DEBIAN/postinst" ]; then
  install -m 755 DEBIAN/postinst "$BUILD_DIR/DEBIAN/postinst"
fi

if [ -f "DEBIAN/postrm" ]; then
  install -m 755 DEBIAN/postrm "$BUILD_DIR/DEBIAN/postrm"
fi

# Copy main executable script into /usr/bin
install -m 755 ./drcwrapper "$BUILD_DIR/usr/bin/drcwrapper"

# Copy documentation and license into /usr/share/doc/drcwrapper
[ -f "README.md" ] && install -m 644 README.md "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}/README.md"
[ -f "BUILD.md" ]  && install -m 644 BUILD.md "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}/BUILD.md"
[ -f "LICENSE" ]   && install -m 644 LICENSE "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}/copyright"

# Build Debian package and enforce root owner/group for all files
dpkg-deb --root-owner-group --build "$BUILD_DIR" "${FINAL_PKG_DIR}.deb"

# Clean up temporary build staging directory
rm -rf "$BUILD_DIR"

echo "Package created successfully: ${FINAL_PKG_DIR}.deb"
