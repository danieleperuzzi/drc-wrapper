#!/bin/bash
set -e

# Check if version argument is provided
if [ -z "$1" ]; then
  echo "Error: missing version argument." >&2
  echo "Usage: $0 <version>" >&2
  echo "Example: $0 1.0.0" >&2
  exit 1
fi

VERSION="$1"
BUILD_DIR="build_arch_staging"

# Clean up previous build directory and artifacts
rm -rf "$BUILD_DIR"

echo "Preparing Arch Linux package build for version ${VERSION}..."

# Create staging directory
mkdir -p "$BUILD_DIR"

# Process PKGBUILD template and inject version number
sed "s/__PKGVER__/${VERSION}/g" Arch/AUR/PKGBUILD.template > "$BUILD_DIR/PKGBUILD"

# Enter staging directory and run makepkg
cd "$BUILD_DIR"

echo "Building Arch Linux package with makepkg..."
# Use -c (clean) and -d (nodeps) to ignore dependency checks
makepkg -cd --noextract --nodeps

# Move generated package back to root directory
mv drc-wrapper-*.pkg.tar.zst ../

# Clean up staging directory
cd ..
rm -rf "$BUILD_DIR"

echo "Arch Linux package built successfully!"
