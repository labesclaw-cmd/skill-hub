# daily-report

每日工作報告自動生成並發信系統。每天 18:30 自動整理當天工作內容，以 .md 附件寄送到指定信箱。

## 功能
- 讀取每日工作日誌（`~/.claude/daily_work_log.md`）
- 自動生成結構化 Markdown 報告
- 以附件形式寄送 Gmail（含日期檔名，不會覆蓋）
- 永久排程（Mac launchd，重開機不消失）

## 安裝需求
- Gmail OAuth 已設定（`~/.claude/gmail_token.json`）
- macOS（launchd 排程）

## 安裝步驟

**步驟 1：複製腳本**
```bash
cp daily_report.sh ~/.claude/daily_report.sh
chmod +x ~/.claude/daily_report.sh
```

**步驟 2：設定收件人**
編輯 `daily_report.sh`，找到這行改成你的信箱：
```bash
msg['To'] = 'your@email.com'
```

**步驟 3：安裝 launchd 排程**
建立 `~/Library/LaunchAgents/com.james.daily-report.plist`，內容：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.james.daily-report</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/你的帳號/.claude/daily_report.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>18</integer>
        <key>Minute</key>
        <integer>30</integer>
    </dict>
</dict>
</plist>
```

載入排程：
```bash
launchctl load ~/Library/LaunchAgents/com.james.daily-report.plist
```

**步驟 4：手動測試**
```bash
bash ~/.claude/daily_report.sh
```

## 每日工作日誌格式
Claude 每天結束對話前會更新 `~/.claude/daily_work_log.md`。
參考 `daily_work_log.example.md` 了解格式。

## 收到的信件
- **主旨**：`Claude 每日工作報告 — YYYY-MM-DD`
- **附件**：`Claude每日報告-YYYY-MM-DD.md`

## 版本
- v1.0.0 — 2026-04-21 初始版本
