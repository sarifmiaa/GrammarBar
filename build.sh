#!/bin/bash
#
# Builds GrammarBar.app from the Swift sources — no Xcode project required.
#
#   ./build.sh              universal binary (Apple Silicon + Intel)
#   ARCHS=arm64 ./build.sh  single architecture (faster)
#
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="GrammarBar"
BUNDLE_ID="local.grammarbar"
VERSION="${VERSION:-1.0.0}"
MIN_MACOS="13.0"
ARCHS="${ARCHS:-arm64 x86_64}"

APP="$APP_NAME.app"
BIN_DIR="$APP/Contents/MacOS"
BUILD_DIR=".build"

SOURCES=()
while IFS= read -r file; do SOURCES+=("$file"); done < <(find Sources -name '*.swift' | sort)

echo "→ Building $APP $VERSION ($ARCHS) from ${#SOURCES[@]} source files"
rm -rf "$APP" "$BUILD_DIR"
mkdir -p "$BIN_DIR" "$BUILD_DIR"

SLICES=()
for arch in $ARCHS; do
  swiftc -O -parse-as-library \
    -target "$arch-apple-macos$MIN_MACOS" \
    -module-name "$APP_NAME" \
    -o "$BUILD_DIR/$APP_NAME-$arch" \
    "${SOURCES[@]}"
  SLICES+=("$BUILD_DIR/$APP_NAME-$arch")
done
lipo -create "${SLICES[@]}" -output "$BIN_DIR/$APP_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_MACOS</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"

echo
echo "✓ Built $(pwd)/$APP"
echo
echo "Run it:"
echo "  open \"$(pwd)/$APP\""
echo
echo "Install it:"
echo "  mv \"$(pwd)/$APP\" /Applications/ && open /Applications/$APP"
