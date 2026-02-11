# Changelog

All notable changes to ClawDrop will be documented in this file.

## [1.1.0] - 2026-02-11

### Added
- Auto-update check (weekly, non-blocking)
- First-run welcome dialog with "Open Config Folder" option
- SHA256 checksum generation in build script
- Colored build output with progress indicators
- Build verification step
- Comprehensive test script for install flow validation

### Changed
- Upgraded build script with better error handling
- Improved launcher with config directory management
- Better Info.plist with LSApplicationCategoryType and NSRequiresAquaSystemAppearance
- Minimum macOS version bumped to 12.0 (Monterey)

### Fixed
- DMG creation fallback when create-dmg not installed

## [1.0.0] - 2026-02-10

### Added
- Initial release
- Self-contained macOS .app bundle with Node.js v22.13.1 LTS
- Bundled OpenClaw CLI (latest)
- One-click DMG installer
- Auto-configuration on first launch
- Launcher script with environment setup
- Landing page at clawdrop.io
- Build script for reproducible builds
