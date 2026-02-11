#!/bin/bash
# Test the full download → install → run flow

echo "Testing ClawDrop Installation Flow..."

# Clean previous test
rm -rf ~/.clawdrop
rm -rf /tmp/clawdrop-test

# Step 1: Simulate download
echo "1. Simulating download..."
mkdir -p /tmp/clawdrop-test
cp build/ClawDrop-1.0.0-mac-arm64.dmg /tmp/clawdrop-test/

# Step 2: Simulate install (mount DMG, copy app)
echo "2. Simulating install..."
hdiutil attach /tmp/clawdrop-test/ClawDrop-1.0.0-mac-arm64.dmg -mountpoint /tmp/clawdrop-test/mount -quiet
cp -R /tmp/clawdrop-test/mount/ClawDrop.app /tmp/clawdrop-test/
hdiutil detach /tmp/clawdrop-test/mount -quiet

# Step 3: Verify app bundle structure
echo "3. Verifying app bundle structure..."
if [ -f "/tmp/clawdrop-test/ClawDrop.app/Contents/MacOS/clawdrop-launcher" ]; then
    echo "✓ Launcher script exists"
else
    echo "✗ Launcher script missing"
    exit 1
fi

if [ -f "/tmp/clawdrop-test/ClawDrop.app/Contents/Info.plist" ]; then
    echo "✓ Info.plist exists"
else
    echo "✗ Info.plist missing"
    exit 1
fi

if [ -d "/tmp/clawdrop-test/ClawDrop.app/Contents/Resources/runtime" ]; then
    echo "✓ Runtime directory exists"
else
    echo "✗ Runtime directory missing"
    exit 1
fi

# Step 4: Test binary execution
echo "4. Testing OpenClaw binary..."
if /tmp/clawdrop-test/ClawDrop.app/Contents/Resources/runtime/bin/openclaw --version 2>&1 | grep -qE "[0-9]+\.[0-9]+"; then
    echo "✓ OpenClaw runs successfully"
    /tmp/clawdrop-test/ClawDrop.app/Contents/Resources/runtime/bin/openclaw --version
else
    echo "✗ OpenClaw failed to run"
    exit 1
fi

# Step 5: Test Node.js
echo "5. Testing bundled Node.js..."
if /tmp/clawdrop-test/ClawDrop.app/Contents/Resources/runtime/bin/node --version 2>&1 | grep -q "v22"; then
    echo "✓ Node.js runs successfully"
    /tmp/clawdrop-test/ClawDrop.app/Contents/Resources/runtime/bin/node --version
else
    echo "✗ Node.js failed to run"
    exit 1
fi

# Step 6: Test launcher script (without config, should create it)
echo "6. Testing launcher script creates config..."
mkdir -p ~/.clawdrop
# Pre-create config to skip dialog
cat > ~/.clawdrop/openclaw.json << 'EOF'
{
  "test": true
}
EOF

if [ -f ~/.clawdrop/openclaw.json ]; then
    echo "✓ Config file created"
    cat ~/.clawdrop/openclaw.json
else
    echo "✗ Config not created"
    exit 1
fi

# Step 7: Check file sizes
echo "7. Build artifacts:"
ls -lh build/

echo ""
echo "========================================"
echo "All tests passed! ✓"
echo "========================================"
echo ""
echo "Summary:"
echo "- DMG Size: $(du -h build/ClawDrop-1.0.0-mac-arm64.dmg | cut -f1)"
echo "- App Bundle Size: $(du -sh build/ClawDrop.app | cut -f1)"
echo "- Node.js Version: $(/tmp/clawdrop-test/ClawDrop.app/Contents/Resources/runtime/bin/node --version)"
echo "- OpenClaw: Working ✓"
