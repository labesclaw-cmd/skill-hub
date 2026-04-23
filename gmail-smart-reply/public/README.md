# gmail-smart-reply

Automatically reads incoming emails and routes Claude's reply based on whether you're at your computer or away.

- **Active** (Claude Code used within threshold): writes reply to a local markdown file + sends macOS notification
- **Away**: sends reply via Gmail API

## Requirements

- macOS
- Claude Code CLI (`claude`) installed
- Gmail API credentials (`gmail_token.json` + `gmail_client_secret.json`)
- A Gmail account with OAuth2 set up

## Setup

### 1. Gmail OAuth credentials

Follow [Google's OAuth2 guide](https://developers.google.com/gmail/api/quickstart/python) to create a project and download `client_secret.json`. Then run the auth flow to generate `gmail_token.json`.

Place both files in `~/.claude/`:
```
~/.claude/gmail_token.json
~/.claude/gmail_client_secret.json
```

### 2. Configure

Edit `gmail_auto_reply.sh` and set:

```bash
ALLOWED_SENDERS=("you@example.com")   # who to accept emails from
ACTIVE_THRESHOLD=1200                  # seconds — 1200 = 20 min
```

Edit the prompt inside the script to match your persona/style.

### 3. Install

```bash
cp gmail_auto_reply.sh ~/.claude/
cp gmail_poller.sh ~/.claude/
chmod +x ~/.claude/gmail_auto_reply.sh ~/.claude/gmail_poller.sh

# Copy and load the launchd plists
cp com.claude.gmail-poller.plist ~/Library/LaunchAgents/
cp com.claude.gmail-auto-reply.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.claude.gmail-poller.plist
launchctl load ~/Library/LaunchAgents/com.claude.gmail-auto-reply.plist
```

### 4. How it works

```
Email arrives
     │
     ▼
gmail_poller.sh (runs every 5 min)
     │ writes gmail_inbox_new.json
     ▼
gmail_auto_reply.sh (triggered by WatchPaths + poller)
     │
     ├─ /tmp/claude-code-active updated < ACTIVE_THRESHOLD?
     │       YES → write to ~/.claude/gmail_terminal_inbox.md
     │             + macOS notification
     │       NO  → send reply via Gmail API
     └─ record ID in gmail_replied_ids.txt (no duplicates)
```

## Files

| File | Purpose |
|------|---------|
| `gmail_poller.sh` | Polls Gmail inbox, downloads attachments, triggers auto_reply |
| `gmail_auto_reply.sh` | Calls Claude, routes reply to terminal or email |
| `com.claude.gmail-poller.plist` | launchd service for poller |
| `com.claude.gmail-auto-reply.plist` | launchd WatchPaths trigger |

## Presence detection

The script checks `/tmp/claude-code-active` — a file updated by Claude Code's `PostToolUse` hook on every tool call. Add this to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "date +%s > /tmp/claude-code-active"
      }]
    }]
  }
}
```

## Viewing terminal replies

```bash
cat ~/.claude/gmail_terminal_inbox.md
```
