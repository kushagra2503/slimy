#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Slimy..."
swift build -c release 2>&1

BINARY=".build/release/Slimy"

if [ ! -f "$BINARY" ]; then
    echo "Build failed: binary not found at $BINARY"
    exit 1
fi

# Create app bundle for proper macOS integration
BUNDLE_DIR="Slimy.app/Contents"
mkdir -p "$BUNDLE_DIR/MacOS"

cp "$BINARY" "$BUNDLE_DIR/MacOS/Slimy"

cat > "$BUNDLE_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.slimy.app</string>
    <key>CFBundleName</key>
    <string>Slimy</string>
    <key>CFBundleExecutable</key>
    <string>Slimy</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc code sign
codesign --force --sign - "$BUNDLE_DIR/MacOS/Slimy" 2>/dev/null || true

echo ""
echo "Build complete!"
echo ""
echo "Run directly:   swift run Slimy"
echo "Run app bundle: open Slimy.app"
echo "Run binary:     .build/release/Slimy"
