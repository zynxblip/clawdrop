# 🪨 ClawDrop

**One-click AI agent installer for macOS.**

ClawDrop packages the entire [OpenClaw](https://github.com/nichochar/openclaw) agent framework into a single drag-and-drop `.app` — no terminal, no Node.js install, no configuration headaches. Download, install, launch. Your AI agent is running in 60 seconds.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-12%2B-000000?logo=apple)](https://github.com/zynxblip/clawdrop/releases)
[![Version](https://img.shields.io/badge/version-1.1.0-6366f1)](https://github.com/zynxblip/clawdrop/releases/tag/v1.1.0)

---

## 🎯 The Problem

Setting up an AI agent framework today means:

```bash
# Install Node.js (hope you pick the right version)
brew install node@22
# Install OpenClaw globally
npm install -g openclaw
# Create config directory
mkdir -p ~/.openclaw
# Write configuration JSON
vim ~/.openclaw/config.json
# Set environment variables
export OPENCLAW_CONFIG_PATH=...
# Start the gateway
openclaw gateway start
# Debug why it didn't work...
```

That's 30–60 minutes of technical work. Most people give up.

## ✅ The Solution

```
1. Download ClawDrop.dmg (211 MB)
2. Drag to Applications
3. Double-click
```

Done. Your agent is running.

---

## 📸 Screenshots

> *Coming soon — see the [landing page](https://zynxblip.github.io/clawdrop/websites/clawdrop/) for a preview.*

---

## ⬇️ Installation

### Download

Grab the latest release from [GitHub Releases](https://github.com/zynxblip/clawdrop/releases).

| File | Size | Platform |
|------|------|----------|
| `ClawDrop-1.1.0-mac-arm64.dmg` | ~211 MB | macOS 12+ (Apple Silicon) |

### Install

1. Open the `.dmg` file
2. Drag `ClawDrop.app` to your Applications folder
3. Launch ClawDrop from Launchpad or Applications

### First Run

On first launch, ClawDrop will:
- Create `~/.clawdrop/` config directory
- Generate a default `openclaw.json` configuration
- Show a welcome dialog with next steps
- Prompt you to add your API keys

### Verify

```bash
# Check the bundled OpenClaw version
/Applications/ClawDrop.app/Contents/Resources/runtime/bin/openclaw --version
```

---

## 🏗 How It Works

ClawDrop is a native macOS `.app` bundle that embeds a complete Node.js runtime and the OpenClaw CLI. No external dependencies are downloaded at install time.

### Architecture

```
┌─────────────────────────────────────────────────┐
│                  ClawDrop.dmg                    │
│                                                  │
│  ┌─────────────────────────────────────────┐    │
│  │            ClawDrop.app                  │    │
│  │                                          │    │
│  │  Contents/                               │    │
│  │  ├── MacOS/                              │    │
│  │  │   └── clawdrop-launcher  ← entry pt  │    │
│  │  ├── Resources/                          │    │
│  │  │   └── runtime/                        │    │
│  │  │       ├── bin/                        │    │
│  │  │       │   ├── node      ← Node.js    │    │
│  │  │       │   └── openclaw  ← CLI        │    │
│  │  │       └── lib/                        │    │
│  │  │           └── node_modules/           │    │
│  │  │               └── openclaw/           │    │
│  │  └── Info.plist                          │    │
│  └─────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘

         ┌───────────────────────┐
         │    On First Launch    │
         ├───────────────────────┤
         │ 1. Create ~/.clawdrop │
         │ 2. Generate config    │
         │ 3. Show welcome       │
         │ 4. Launch OpenClaw    │
         └───────────────────────┘
```

### Launcher Flow

```
User double-clicks ClawDrop.app
        │
        ▼
clawdrop-launcher (bash)
        │
        ├─ First run? → Create config → Show dialog → Exit
        │
        ├─ Check for updates (weekly, background)
        │
        └─ exec openclaw (with bundled Node.js)
                │
                ▼
        OpenClaw Gateway running
        Agent ready on Telegram/Discord/etc.
```

---

## 🌊 Why Solana?

AI agents are the next billion users of crypto infrastructure. They need to:

- **Own wallets** — agents that manage funds autonomously
- **Make payments** — micropayments for API calls, tool usage, agent-to-agent commerce
- **Transact on-chain** — DeFi, NFTs, governance participation

Solana's sub-second finality and <$0.01 transactions make it the only chain fast and cheap enough for real-time agent economies. ClawDrop is the on-ramp — making it trivial to deploy agents that can plug into Solana tooling.

---

## 🔧 Build From Source

```bash
# Clone the repo
git clone https://github.com/zynxblip/clawdrop.git
cd clawdrop

# Run the build script (requires macOS + curl)
./scripts/build-clawdrop-v1.1.0.sh

# Output:
#   build/ClawDrop.app
#   build/ClawDrop-1.1.0-mac-arm64.dmg
#   build/ClawDrop-1.1.0-mac-arm64.dmg.sha256
```

### Build Requirements
- macOS 12+
- `curl`
- ~1 GB free disk space
- Internet connection (to download Node.js + OpenClaw)

### Test the Build

```bash
./scripts/test-install-flow.sh
```

---

## 🗺 Roadmap

- [x] macOS Apple Silicon support (v1.0)
- [x] Auto-configuration on first run (v1.0)
- [x] Update notifications (v1.1)
- [ ] macOS Intel universal binary
- [ ] Code signing & notarization
- [ ] Built-in API key setup wizard (GUI)
- [ ] Windows installer (.msi)
- [ ] Linux AppImage / .deb
- [ ] One-click skill marketplace
- [ ] Auto-update (in-place)
- [ ] Pre-configured Solana wallet integration

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. **Fork** the repo
2. **Create** a feature branch (`git checkout -b feature/amazing-thing`)
3. **Commit** your changes (`git commit -m 'Add amazing thing'`)
4. **Push** to the branch (`git push origin feature/amazing-thing`)
5. **Open** a Pull Request

### Areas We Need Help

- **Windows port** — packaging Node.js + OpenClaw into an .msi installer
- **Linux port** — AppImage or .deb packaging
- **Code signing** — Apple Developer Program enrollment & notarization
- **GUI setup wizard** — native macOS UI for first-run configuration
- **Testing** — try it on your Mac and report issues!

---

## 📄 License

MIT — see [LICENSE](LICENSE).

---

## 👥 Team

Built by **Rocky** 🪨 (AI agent running on OpenClaw) and **Zac** (human).

- GitHub: [@zynxblip](https://github.com/zynxblip)
- Email: rockytherobot@icloud.com

---

<p align="center">
  <i>ClawDrop: Infrastructure for the agent economy.</i>
</p>
