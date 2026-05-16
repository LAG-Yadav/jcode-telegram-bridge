# Jcode Telegram Bridge

**Connect Telegram messages directly into your Jcode AI session.**

Telegram user → Bot API → Bridge injects into Jcode debug socket → Jcode responds naturally → Bridge sends back to Telegram

No subprocess spawning. No separate AI provider config. No webhooks needed. Just polling + Unix socket injection.

## How it Works

```
┌─────────┐   Telegram API    ┌──────────┐   Unix Socket    ┌──────┐
│ Telegram ├──────────────────►│  Bridge  ├─────────────────►│ Jcode│
│  User    │◄─────────────────│ (polling)│◄─────────────────│  AI  │
└─────────┘                   └──────────┘                  └──────┘
```

1. Bridge polls Telegram for new messages (long-poll `getUpdates`)
2. Injects the message into Jcode via `debug_socket` as a client message
3. A watcher thread polls `last_response` until a new response appears
4. Sends the response back to the Telegram user

## Features

- **Direct injection** — messages appear in your Jcode terminal as `📩 *Telegram from X*: ...`
- **Natural responses** — Jcode replies in its own voice, no templated bot messages
- **Full duplex** — both Telegram→Jcode and future Jcode→Telegram (via `tgsend`)
- **Zero dependencies** — pure Python stdlib. Install python3 and go.
- **File-based persistence** — inbox/sent logs survive restarts
- **Auto-detection** — finds Jcode debug socket from common locations
- **Background watcher** — separate thread watches for responses so you never miss one

## Installation

### Quick Install (one-liner)

```bash
bash <(curl -s https://raw.githubusercontent.com/LAG-Yadav/jcode-telegram-bridge/main/install.sh)
```

### Manual Install

```bash
# Clone into jcode data directory
git clone https://github.com/LAG-Yadav/jcode-telegram-bridge.git ~/.jcode/telegram

# Make helper scripts accessible
mkdir -p ~/.jcode/bin
cp ~/.jcode/telegram/bin/* ~/.jcode/bin/
echo 'export PATH="$PATH:$HOME/.jcode/bin"' >> ~/.bashrc
source ~/.bashrc

# Configure (installer creates .env automatically)
nano ~/.jcode/telegram/.env
# Set TELEGRAM_BOT_TOKEN=your_token_here
```

## Configuration

### 1. Get a Telegram Bot Token

Talk to [@BotFather](https://t.me/botfather) on Telegram:

```
/start
/newbot
NameIt: JcodeBridge
Username: @YourBotUsername
```

Save the token like `123456789:ABCdefGHIjklmNOPqrstUVwxyz`.

### 2. Configure

Edit `~/.jcode/telegram/.env`:

```env
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklmNOPqrstUVwxyz
```

### 3. Enable Jcode Debug Socket

Add to your Jcode config (`~/.jcode/config.toml`):

```toml
[display]
debug_socket = true
```

Restart Jcode.

### 4. Start the Bridge

```bash
tgstart
```

Check status:
```bash
tgstatus
```

Read recent messages:
```bash
tgread
```

## Usage

### Send to Telegram from Jcode

If Jcode wants to proactively message a Telegram user:

```bash
tgsend <chat_id> Your message here
```

### Read Recent Messages from Terminal

```bash
tgread 5   # last 5 messages
```

## System Prompt

Add this to your Jcode system prompt so it knows about the bridge:

```markdown
## Telegram Bridge

I have a Telegram bridge running. Messages from Telegram users appear 
in my terminal as:
  `📩 *Telegram from {name}*: {message}`

When I see one of these, I should:
1. Understand it's a user sending me a message via Telegram
2. Respond naturally to their query/request
3. My response will automatically be sent back to them via the bridge

The bridge handles delivery automatically — I just need to reply normally.
Messages from Telegram users are real requests that need my attention.
```

## Helper Scripts

| Script | Purpose |
|--------|---------|
| `tgstatus` | Check if bridge is running, show message counts |
| `tgstart` | Start the bridge daemon |
| `tgsend <cid> <msg>` | Send a message to a Telegram chat ID |
| `tgread [n]` | Read last N Telegram messages (default 10) |

## Troubleshooting

### "Socket not found"

The bridge can't find the Jcode debug socket. Make sure:
- Jcode is running
- `debug_socket = true` is in `~/.jcode/config.toml`
- The socket exists at one of the common paths:
  ```bash
  ls -la /run/user/*/jcode-debug.sock /tmp/jcode-debug.sock ~/.jcode/debug.sock
  ```
- Set `JCODE_DEBUG_SOCKET` explicitly in `.env` if auto-detection fails

### "Connection refused"

Jcode is running but not accepting socket connections. Restart Jcode with the config change.

### Bridge sends empty responses

The `last_response` command may return cached/old data. The watcher thread handles this, but if responses are empty:
- Check Jcode is actually generating responses
- Increase `RESPONSE_TIMEOUT` in `.env`

## License

MIT — use freely, contribute back.
