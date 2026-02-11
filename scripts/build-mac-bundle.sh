#!/bin/bash
set -e

echo "Building ClawDrop Mac Bundle..."

# Configuration
NODE_VERSION="22.13.1"
APP_NAME="ClawDrop"
BUNDLE_ID="com.rocky.clawdrop"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="ClawDrop-1.0.0-mac-arm64.dmg"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Step 1: Download Node.js runtime
echo "Downloading Node.js v$NODE_VERSION..."
mkdir -p "$BUILD_DIR/runtime"
curl -fsSL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-darwin-arm64.tar.gz" | \
    tar xz -C "$BUILD_DIR/runtime" --strip-components=1

# Step 2: Install OpenClaw
echo "Installing OpenClaw..."
"$BUILD_DIR/runtime/bin/npm" install -g openclaw --prefix "$BUILD_DIR/runtime"

# Step 3: Create .app bundle structure
echo "Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy runtime
cp -R "$BUILD_DIR/runtime" "$APP_BUNDLE/Contents/Resources/"

# Create launcher script
cat > "$APP_BUNDLE/Contents/MacOS/clawdrop-launcher" << 'EOF'
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH="$DIR/../Resources/runtime/bin:$PATH"
export NODE_PATH="$DIR/../Resources/runtime/lib/node_modules"
CONFIG_DIR="$HOME/.clawdrop"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"

if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << 'CONFIGEOF'
{
  // ClawDrop Configuration
  // Add your API key and bot token here
  "agent": {
    "name": "MyAgent",
    "model": "router/auto"
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN_HERE"
    }
  }
}
CONFIGEOF
    osascript -e 'display dialog "First run! Please edit config at ~/.clawdrop/openclaw.json" buttons {"OK"} default button "OK"'
fi

export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"
exec "$DIR/../Resources/runtime/bin/openclaw" "$@"
EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/clawdrop-launcher"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>clawdrop-launcher</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Step 4: Create DMG
echo "Creating DMG..."
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "$APP_NAME Installer" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --app-drop-link 600 185 \
        "$BUILD_DIR/$DMG_NAME" \
        "$APP_BUNDLE"
else
    echo "create-dmg not installed, creating basic DMG..."
    # Fallback to hdiutil
    TMP_DMG="$BUILD_DIR/temp.dmg"
    echo "Creating DMG with hdiutil (800MB)..."
    hdiutil create -srcfolder "$APP_BUNDLE" -volname "$APP_NAME" -fs HFS+ -size 800m "$TMP_DMG"
    mv "$TMP_DMG" "$BUILD_DIR/$DMG_NAME"
fi

echo "Build complete!"
echo "Output: $BUILD_DIR/$DMG_NAME"
echo "App Bundle: $APP_BUNDLE"
ls -lh "$BUILD_DIR/$DMG_NAME"
