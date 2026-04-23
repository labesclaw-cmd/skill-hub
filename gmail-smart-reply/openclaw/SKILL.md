# Skill: gmail-smart-reply

## 用途
收到 BOSS 的 email 時，自動判斷 BOSS 是否在電腦前，決定要回 email 還是寫入終端機。

## 觸發條件
- `gmail_poller.sh` 偵測到白名單新信
- launchd WatchPaths 監控 `~/.claude/gmail_inbox_new.json` 變動

## 在電腦前的判斷邏輯
- 讀取 `/tmp/claude-code-active`（由 PostToolUse hook 寫入，記錄最後工具呼叫的 Unix timestamp）
- 若距現在 < 1200 秒（20 分鐘）→ **終端機模式**
- 若距現在 ≥ 1200 秒 → **Email 模式**

## 終端機模式
1. 呼叫 `claude -p` 分析信件內容
2. 回覆寫入 `~/.claude/gmail_terminal_inbox.md`
3. 發送 macOS 通知（右上角彈出）
4. 不寄 email

## Email 模式
1. 呼叫 `claude -p` 分析並生成回信
2. 用 Gmail API（OAuth2 refresh_token）寄出回信
3. 保留 threadId 讓回信在同一對話串

## 防重複機制
- 已處理過的 mail ID 記錄在 `~/.claude/gmail_replied_ids.txt`
- Lock file `/tmp/gmail_auto_reply.lock` 防止並發執行

## 關鍵路徑
- `~/.claude/gmail_auto_reply.sh` — 主腳本
- `~/.claude/gmail_poller.sh` — Gmail 輪詢（含附件下載）
- `~/.claude/gmail_inbox_new.json` — 最新收件匣快照
- `~/.claude/gmail_terminal_inbox.md` — 終端機模式的回覆輸出
- `~/Library/LaunchAgents/com.james.gmail-auto-reply.plist` — WatchPaths 觸發器
- `~/Library/LaunchAgents/com.james.gmail-poller.plist` — 定時輪詢服務

## 允許的寄件人白名單
在 `gmail_poller.sh` 的 `ALLOWED_SENDERS` 陣列中設定：
```bash
ALLOWED_SENDERS=("chenyuchi09@gmail.com")
```

## 閒置門檻調整
在 `gmail_auto_reply.sh` 中修改：
```bash
ACTIVE_THRESHOLD=1200   # 秒，改這個數字即可
```

## 附件支援
poller 自動下載 jpg/png/gif/webp/heic/pdf/txt/md 到 `~/.claude/gmail_attachments/`，檔名格式：`YYYY-MM-DD_主旨_原檔名`

## 已知限制
- Claude CLI 必須先登入（`claude` 指令可用）
- Gmail OAuth token 需定期確認未過期
- macOS 通知需系統允許終端機發送通知
