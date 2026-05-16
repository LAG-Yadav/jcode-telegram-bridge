#!/usr/bin/env bash
set -euo pipefail

# Jcode Telegram Bridge - Installer
# Run: bash <(curl -s https://raw.githubusercontent.com/1jehuang/jcode-telegram-bridge/main/install.sh)

REPO="https://github.com/1jehuang/jcode-telegram-bridge.git"
INSTALL_DIR="$HOME/.jcode/telegram"
BIN_DIR="$HOME/.jcode/bin"

echo "╔════════════════════════════════════════╗"
echo "║   Jcode Telegram Bridge Installer      ║"
echo "╚════════════════════════════════════════╝"

# Check prerequisites
echo ""
echo "🔍 Checking prerequisites..."

# Python3
if ! command -v python3 &>/dev/null; then
    echo "❌ python3 not found. Install it first."
    exit 1
fi
echo "✅ python3 $(python3 --version | cut -d' ' -f2)"

# Git
if command -v git &>/dev/null; then
    echo "✅ git"
    CLONE_METHOD="git"
elif command -v curl &>/dev/null; then
    echo "⚠️ git not found, using curl fallback"
    CLONE_METHOD="curl"
else
    echo "❌ Need git or curl to download files."
    exit 1
fi

# Jcode
if ! command -v jcode &>/dev/null; then
    echo "⚠️ jcode not found in PATH. The bridge needs Jcode running."
    echo "   Install from: https://github.com/1jehuang/jcode"
fi

# Create directories
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

# Download files
echo ""
echo "📥 Downloading bridge files..."

if [ "$CLONE_METHOD" = "git" ]; then
    TMPDIR=$(mktemp -d)
    git clone --depth 1 "$REPO" "$TMPDIR" 2>/dev/null
    cp "$TMPDIR/bridge.py" "$INSTALL_DIR/"
    cp "$TMPDIR/.env.example" "$INSTALL_DIR/.env.example"
    cp "$TMPDIR/bin/"* "$BIN_DIR/"
    rm -rf "$TMPDIR"
else
    for file in bridge.py .env.example; do
        curl -sf "https://raw.githubusercontent.com/1jehuang/jcode-telegram-bridge/main/$file" \
            -o "$INSTALL_DIR/$file"
    done
    for file in tgsend tgread tgstatus tgstart; do
        curl -sf "https://raw.githubusercontent.com/1jehuang/jcode-telegram-bridge/main/bin/$file" \
            -o "$BIN_DIR/$file"
    done
fi

chmod +x "$BIN_DIR/"*

# Add to PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    echo "" >> "$SHELL_CONFIG"
    echo "# Jcode Telegram Bridge" >> "$SHELL_CONFIG"
    echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$SHELL_CONFIG"
    echo "✅ Added $BIN_DIR to PATH in $SHELL_CONFIG"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    INSTALLATION COMPLETE                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "1. Create a Telegram bot via @BotFather and get your token"
echo "   See: https://t.me/botfather"
echo ""
echo "2. Configure your bot token:"
echo "   cp $INSTALL_DIR/.env.example $INSTALL_DIR/.env"
echo "   nano $INSTALL_DIR/.env"
echo "   # Set TELEGRAM_BOT_TOKEN=your_token_here"
echo ""
echo "3. Make sure Jcode is running with debug_socket enabled:"
echo "   Add to ~/.jcode/config.toml:"
echo "     [display]"
echo "     debug_socket = true"
echo ""
echo "4. Start the bridge:"
echo "   tgstart"
echo ""
echo "5. Check status:"
echo "   tgstatus"
echo ""
echo "6. Tell Jcode about the bridge (system prompt in README):"
echo "   \"I have the Telegram bridge running. When you see"
echo "    '📩 *Telegram from ...' messages, reply naturally.\""
echo ""
