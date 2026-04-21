# claude-notify

Claude 阻礙通知系統。當 Claude 執行任務遇到需要用戶確認的情況時，自動發送 Gmail 通知。

## 功能
- **08:00-22:00**：遇到阻礙立即發信通知
- **22:00-08:00**：靜默累積，隔天 08:00 統一發早報
- 避免半夜打擾用戶睡眠

## 安裝需求
- Gmail OAuth 已設定（`~/.claude/gmail_token.json`）
- macOS launchd（早報排程）

## 使用方式

### 即時通知（遇到阻礙時呼叫）
```bash
bash ~/skill-hub/claude-notify/notify.sh alert "任務說明，例如：安裝 Ollama 需要確認是否覆蓋現有版本"
```

### 早報（系統自動排程，每天 08:00）
```bash
bash ~/skill-hub/claude-notify/notify.sh morning
```

### 手動測試
```bash
# 測試即時通知
bash ~/skill-hub/claude-notify/notify.sh alert "這是一個測試通知"

# 測試早報
bash ~/skill-hub/claude-notify/notify.sh morning
```

## 收到的信件格式

**即時通知（主旨）**：⚠️ Claude 需要你確認

**早報（主旨）**：☀️ Claude 昨夜卡住的任務（早報）

## 設定早報排程（launchd）
```bash
# 安裝排程
launchctl load ~/Library/LaunchAgents/com.james.claude-notify-morning.plist
```

## 適用系統
- Claude Code（主要）
- 可擴展至 OpenClaw、Hermes

## 版本
- v1.0.0 — 2026-04-21 初始版本
