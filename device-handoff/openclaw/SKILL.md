# Skill: device-handoff

## 用途
在終端機（Claude Code）和 Discord（手機/DC）之間無縫切換，並透過結構化交接摘要保留對話脈絡。

## 觸發詞

### 終端機 → Discord（由 Lapis/SOUL.md 執行）
- `切換到手機`
- `切換到dc`
- `切換到DC`
- `切換到discord`
- `切換到Discord`

### Discord → 終端機（由 index.js 執行）
- `切換回電腦`
- `切換到電腦`

## 終端機端流程（SOUL.md 規定）
1. 生成結構化交接摘要（上限 300 token）
2. `exec` 寫入 `~/.claude/handoff.md`（覆寫，不追加）
3. 回覆：「📱 已準備交接，手機那邊發第一則訊息即可接續。」

## Discord 端流程（index.js）
- **切換到電腦**：把 buffer 摘要寫入 `~/.claude/handoff.md`，告知 BOSS 執行 `bash ~/continue-phone.sh`
- **新 session 第一則訊息**：自動讀取並注入 `handoff.md`，讀完即刪除

## 關鍵路徑
- `~/skill-hub/claude-discord-bridge/index.js` — Discord bot 主程式
- `~/.openclaw/workspace/SOUL.md` → 切換手機交接段落
- `~/.claude/handoff.md` — 交接資料（TTL 2hr，讀後即刪）
- `~/continue-phone.sh` — 在終端機接續 Discord 的對話
- `~/Library/LaunchAgents/com.james.claude-discord-bridge.plist` — launchd 常駐服務

## 交接摘要格式
```markdown
# 交接摘要（電腦 → 手機）— [時間]

## 剛才在討論
[2-3 行摘要]

## 未完成的事
- [最多 3 條]

## 需要知道的關鍵點
- [最多 3 條]
```

## 防暴增設計
- handoff.md 上限 300 token，超出截斷
- 每次覆寫，不追加
- 2 小時後自動失效並刪除
- Discord buffer 最多保留 20 則，summary 取最近 10 則

## Discord Bot 設定
- Token 從 `~/.claude/discord_config.sh` 讀取：`DISCORD_BOT_TOKEN="xxx"`
- Owner ID 由 launchd env var `DISCORD_OWNER_ID` 設定
- 需開啟 Message Content Intent + Server Members Intent

## 指令（Discord 頻道內）
- `!reset` — 清除 session buffer
- `!status` — 顯示 session 狀態與待交接
