# device-handoff

Seamless context switching between Claude Code (terminal) and Discord — with structured handoff summaries so your AI assistant picks up exactly where you left off.

## How it works

```
Terminal (Claude Code)          Discord Bot (ClaudeBridge)
        │                               │
  "切換到手機"              ←→       "切換回電腦"
  "切換到dc"                         "切換到電腦"
  "切換到discord"
        │                               │
        ▼                               ▼
  writes handoff.md              reads handoff.md
  (≤300 token summary)           injects into next prompt
  deletes after 2hr              deletes after reading
```

## Features

- **One-way context carry**: structured summary (what we discussed, pending tasks, key points)
- **Token-efficient**: hard cap of 300 tokens, overwrite-only (no accumulation)
- **Auto-expire**: handoff file deletes itself after 2 hours
- **Dual-direction**: terminal → Discord and Discord → terminal

## Components

| File | Role |
|------|------|
| `index.js` | Discord bot (discord.js v14) |
| `continue-phone.sh` | Resume in terminal after Discord session |
| `com.claude.discord-bridge.plist` | launchd service |

## Setup

### 1. Discord Bot

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create new application → Bot → copy token
3. Enable **Message Content Intent** and **Server Members Intent**
4. Add bot to your server with `bot` scope + `Send Messages`, `Read Message History` permissions

### 2. Configure

Edit `index.js`:
```js
const TOKEN    = 'YOUR_DISCORD_BOT_TOKEN';
const OWNER_ID = 'YOUR_DISCORD_USER_ID';   // only respond to this user
```

Edit `com.claude.discord-bridge.plist` — replace `YOUR_USERNAME` and insert your token/owner ID.

### 3. Install

```bash
npm install discord.js
cp index.js ~/discord-bridge/
cp continue-phone.sh ~/
chmod +x ~/continue-phone.sh

cp com.claude.discord-bridge.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.claude.discord-bridge.plist
```

## Trigger words

| Said in | Phrase | Action |
|---------|--------|--------|
| Terminal | `切換到手機` / `切換到dc` / `切換到discord` | Write handoff → switch to Discord |
| Discord | `切換回電腦` / `切換到電腦` | Write handoff → switch to terminal |
| Terminal | `bash ~/continue-phone.sh` | Resume from Discord handoff |

## Commands (Discord)

| Command | Action |
|---------|--------|
| `!reset` | Clear session buffer |
| `!status` | Show session state and pending handoff |

## Handoff format

```markdown
# 交接摘要（電腦 → 手機）— 2026-04-23 10:30

## 剛才在討論
[2–3 line summary]

## 未完成的事
- item 1
- item 2

## 需要知道的關鍵點
- key point 1
```

## Customization

- Change trigger words: search for `切換` in `index.js` and `SOUL.md`/your system prompt
- Adjust handoff TTL: `HANDOFF_TTL` in `index.js` (seconds, default 7200 = 2hr)
- Adjust summary length: edit the prompt in your AI system instructions
