#!/bin/bash
set -e

# ClawDrop Build Script v1.1.0
# One-click OpenClaw installer for macOS

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                 ClawDrop Builder v1.1.0                      ║"
echo "║           One-click OpenClaw Installer                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
NODE_VERSION="22.13.1"
NODE_MAJOR="22"
APP_NAME="ClawDrop"
BUNDLE_ID="com.rocky.clawdrop"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="ClawDrop-1.1.0-mac-arm64.dmg"
VERSION="1.1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [[ $(uname -m) != "arm64" ]]; then
        log_warn "Building on Intel Mac. Output will still work on both architectures."
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Clean build directory
clean_build() {
    log_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    log_success "Build directory ready"
}

# Download Node.js runtime
download_node() {
    log_info "Downloading Node.js v$NODE_VERSION..."
    mkdir -p "$BUILD_DIR/runtime"
    
    local node_url="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-darwin-arm64.tar.gz"
    
    if ! curl -fsSL "$node_url" | tar xz -C "$BUILD_DIR/runtime" --strip-components=1; then
        log_error "Failed to download Node.js"
        exit 1
    fi
    
    log_success "Node.js v$NODE_VERSION downloaded"
}

# Install OpenClaw (latest version)
install_openclaw() {
    log_info "Installing latest OpenClaw..."
    
    export PATH="$BUILD_DIR/runtime/bin:$PATH"
    export npm_config_prefix="$BUILD_DIR/runtime"
    
    if ! "$BUILD_DIR/runtime/bin/npm" install -g openclaw@latest; then
        log_error "Failed to install OpenClaw"
        exit 1
    fi
    
    # Verify installation
    local openclaw_version=$("$BUILD_DIR/runtime/bin/openclaw" --version 2>/dev/null || echo "unknown")
    log_success "OpenClaw installed (version: $openclaw_version)"
}

# Create .app bundle structure
create_app_bundle() {
    log_info "Creating app bundle..."
    
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    
    # Copy runtime
    cp -R "$BUILD_DIR/runtime" "$APP_BUNDLE/Contents/Resources/"
    
    log_success "App bundle structure created"
}

# Create launcher script
create_launcher() {
    log_info "Creating launcher script..."
    
    cat > "$APP_BUNDLE/Contents/MacOS/clawdrop-launcher" << 'EOF'
#!/bin/bash

# ClawDrop Launcher v1.1.0
# One-click OpenClaw runner

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="ClawDrop"
VERSION="1.1.0"

# Setup paths
export PATH="$DIR/../Resources/runtime/bin:$PATH"
export NODE_PATH="$DIR/../Resources/runtime/lib/node_modules"

# Config directories
CONFIG_DIR="$HOME/.clawdrop"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
FIRST_RUN_FILE="$CONFIG_DIR/.first-run-complete"

# First run setup
if [ ! -f "$FIRST_RUN_FILE" ]; then
    echo "🚀 First run detected. Setting up ClawDrop..."
    
    mkdir -p "$CONFIG_DIR"
    
    # Create default config
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'CONFIGEOF'
{
  "_comment": "ClawDrop Configuration - Generated on first run",
  "agent": {
    "name": "MyAgent",
    "model": "router/auto",
    "workspace": "~/.openclaw/workspace"
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "auth": {
      "mode": "token"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN_HERE"
    }
  },
  "models": {
    "defaults": {
      "primary": "moonshot/kimi-k2.5"
    }
  }
}
CONFIGEOF
    fi
    
    # Show first-run dialog
    osascript << 'APPLESCRIPT'
        display dialog "Welcome to ClawDrop! 🚀\n\nClawDrop has been installed successfully.\n\nNext steps:\n1. Edit ~/.clawdrop/openclaw.json\n2. Add your Telegram bot token\n3. Restart ClawDrop\n\nNeed help? Visit clawdrop.io/docs" buttons {"Open Config Folder", "OK"} default button "OK"
        set buttonPressed to button returned of result
        if buttonPressed is "Open Config Folder" then
            do shell script "open ~/.clawdrop"
        end if
APPLESCRIPT
    
    # Mark first run complete
    touch "$FIRST_RUN_FILE"
    
    echo "✅ First run setup complete!"
    echo "📝 Please edit $CONFIG_FILE and restart ClawDrop"
    exit 0
fi

# Check for updates (weekly)
UPDATE_CHECK_FILE="$CONFIG_DIR/.last-update-check"
if [ ! -f "$UPDATE_CHECK_FILE" ] || [ $(($(date +%s) - $(stat -f %m "$UPDATE_CHECK_FILE" 2>/dev/null || echo 0))) -gt 604800 ]; then
    # Check for updates in background
    (
        LATEST=$(curl -s https://api.github.com/repos/zynxblip/clawdrop/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [ "$LATEST" != "v1.1.0" ] && [ -n "$LATEST" ]; then
            echo "🔄 Update available: $LATEST (current: v1.1.0)"
            echo "   Download at: https://clawdrop.io/download"
        fi
    ) &
    touch "$UPDATE_CHECK_FILE"
fi

# Set config path
export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"

# Launch OpenClaw
exec "$DIR/../Resources/runtime/bin/openclaw" "$@"
EOF

    chmod +x "$APP_BUNDLE/Contents/MacOS/clawdrop-launcher"
    log_success "Launcher script created"
}

# Create Info.plist
create_info_plist() {
    log_info "Creating Info.plist..."
    
    cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>clawdrop-launcher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
EOF

    log_success "Info.plist created"
}

# Create DMG installer
create_dmg() {
    log_info "Creating DMG installer..."
    
    if command -v create-dmg &> /dev/null; then
        create-dmg \
            --volname "$APP_NAME Installer" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --app-drop-link 600 185 \
            "$BUILD_DIR/$DMG_NAME" \
            "$APP_BUNDLE" \
            2>/dev/null || true
    fi
    
    # Fallback to hdiutil if create-dmg fails or isn't installed
    if [ ! -f "$BUILD_DIR/$DMG_NAME" ]; then
        log_warn "create-dmg not available, using hdiutil fallback"
        
        local tmp_dmg="$BUILD_DIR/temp.dmg"
        local staging="$BUILD_DIR/staging"
        
        mkdir -p "$staging"
        cp -R "$APP_BUNDLE" "$staging/"
        
        hdiutil create -srcfolder "$staging" -volname "$APP_NAME" -fs HFS+ -size 800m "$tmp_dmg"
        mv "$tmp_dmg" "$BUILD_DIR/$DMG_NAME"
        rm -rf "$staging"
    fi
    
    log_success "DMG created: $DMG_NAME"
}

# Verify build
verify_build() {
    log_info "Verifying build..."
    
    # Check app bundle exists
    if [ ! -d "$APP_BUNDLE" ]; then
        log_error "App bundle not found"
        exit 1
    fi
    
    # Check launcher is executable
    if [ ! -x "$APP_BUNDLE/Contents/MacOS/clawdrop-launcher" ]; then
        log_error "Launcher not executable"
        exit 1
    fi
    
    # Check OpenClaw is installed
    if [ ! -f "$APP_BUNDLE/Contents/Resources/runtime/bin/openclaw" ]; then
        log_error "OpenClaw not found in bundle"
        exit 1
    fi
    
    # Get sizes
    local app_size=$(du -sh "$APP_BUNDLE" | cut -f1)
    local dmg_size=$(du -sh "$BUILD_DIR/$DMG_NAME" 2>/dev/null | cut -f1 || echo "N/A")
    
    log_success "Build verification passed"
    echo ""
    echo "📊 Build Statistics:"
    echo "   App Bundle: $app_size"
    echo "   DMG Size:   $dmg_size"
    echo "   OpenClaw:   $("$APP_BUNDLE/Contents/Resources/runtime/bin/openclaw" --version 2>/dev/null || echo "unknown")"
}

# Generate checksums
generate_checksums() {
    log_info "Generating checksums..."
    
    cd "$BUILD_DIR"
    shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
    
    log_success "Checksums generated"
}

# Main build process
main() {
    echo "Starting build process..."
    echo ""
    
    check_prerequisites
    clean_build
    download_node
    install_openclaw
    create_app_bundle
    create_launcher
    create_info_plist
    create_dmg
    verify_build
    generate_checksums
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   BUILD COMPLETE! 🎉                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📦 Output Files:"
    echo "   DMG:     $BUILD_DIR/$DMG_NAME"
    echo "   App:     $APP_BUNDLE"
    echo "   SHA256:  $BUILD_DIR/$DMG_NAME.sha256"
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Test: Open $DMG_NAME and drag to Applications"
    echo "   2. Verify: Launch ClawDrop.app and complete first-run setup"
    echo "   3. Upload: Release to GitHub / clawdrop.io"
    echo ""
    echo "📝 Build Info:"
    echo "   Version:    v$VERSION"
    echo "   Node.js:    v$NODE_VERSION"
    echo "   Built:      $(date)"
    echo ""
}

# Run main
main "$@"
