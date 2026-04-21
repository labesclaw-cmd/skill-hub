# 🗂️ ai-catalog

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Platform: macOS](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://www.apple.com/tw/macos/) [![Python 3.8+](https://img.shields.io/badge/Python-3.8+-green.svg)](https://www.python.org/)

> 個人 AI 工具目錄系統，搭配深色主題的桌面 HTML 查閱介面，支援多 Agent 分頁顯示與狀態追蹤。

## ✨ 核心特色

- 📱 **分頁式檢視** — 依 Agent 類型（Claude、OpenClaw、Hermes、通用 AI 工具）分類顯示
- 🎨 **深色主題介面** — 舒適的深色模式 HTML 頁面，適合長時間查閱
- 🏷️ **狀態追蹤** — 支援四種狀態：已安裝✅、待處理⏳、待評估🔍、無法使用❌
- ⚡ **CLI 新增工具** — 透過 `catalog-add.sh` 快速新增工具條目
- 🔄 **自動更新** — 修改 `catalog.md` 後自動重新生成 HTML（macOS launchd）
- 🤖 **Node.js API** — 提供 `index.js` 模組供 OpenClaw 等 Agent 程式化呼叫

## 🖼️ 畫面預覽

![AI工具目錄截圖](docs/screenshot.png)

## 🏗️ 技術架構

本專案採用簡單的架構設計：

- **資料層** — `ai-tools-catalog.md` 作為 Markdown 格式的資料來源，維護成本低且易於版本控制
- **生成層** — `bin/generate.py` 解析 Markdown 表格，輸出深色主題的分頁式 HTML
- **CLI 層** — `bin/catalog-add.sh` 提供命令列介面，新增工具時自動觸發 HTML 重新生成
- **API 層** — `index.js` 封裝為 Node.js 模組，供 Agent 程式化存取目錄資料

## 📁 專案結構

```
ai-catalog/
├── bin/
│   ├── generate.py      # 解析 Markdown → 生成深色主題 HTML
│   └── catalog-add.sh   # CLI 新增工具並自動重新生成
├── index.js             # Node.js API 模組（add/list/regenerate）
├── skill.json           # Skill 元資料
├── ai-tools-catalog.md  # Markdown 表格資料來源
├── docs/
│   └── screenshot.png   # 畫面截圖
├── LICENSE              # MIT 授權條款
└── README.md            # 本文件
```

## 🚀 快速開始

### 前置需求

- macOS 作業系統
- Python 3.8 以上
- Node.js 18 以上（若需使用 Node.js API）

### 安裝步驟

1. **Clone 專案**
   ```bash
   git clone https://github.com/your-username/ai-catalog.git
   cd ai-catalog
   ```

2. **確保執行權限**
   ```bash
   chmod +x bin/generate.py bin/catalog-add.sh
   ```

3. **初始化目錄**
   ```bash
   # 首次生成 HTML
   python3 bin/generate.py
   ```

4. **設定 launchd 自動更新**（可選）
   ```bash
   # 將 launchd 設定檔複製到 ~/Library/LaunchAgents/
   cp com.ai-catalog.watcher.plist ~/Library/LaunchAgents/
   launchctl load ~/Library/LaunchAgents/com.ai-catalog.watcher.plist
   ```

5. **開啟 HTML 檢視**
   ```bash
   open ai-tools-catalog.html
   ```

## 💡 使用範例

### 使用 CLI 新增工具

```bash
# 新增一個 Claude 工具
./bin/catalog-add.sh \
  --name "Claude Desktop" \
  --agent claude \
  --url "https://claude.ai/desktop" \
  --status installed \
  --description "Anthropic 出品的 AI 助手桌面應用"

# 新增一個待評估的 OpenClaw 工具
./bin/catalog-add.sh \
  --name "OpenClaw CLI" \
  --agent openclaw \
  --url "https://github.com/openclaw/cli" \
  --status evaluating \
  --description "OpenClaw 命令列介面"
```

### 直接編輯 Markdown

```markdown
| 名稱 | Agent | URL | 狀態 | 說明 |
|------|-------|-----|------|------|
| Claude Desktop | Claude | https://claude.ai/desktop | ✅ | Anthropic AI 助手 |
| OpenClaw CLI | OpenClaw | https://github.com/openclaw/cli | 🔍 | 開源 CLI 工具 |
```

## 🤖 Agent 整合（OpenClaw / Node.js）

`index.js` 提供程式化介面供 Agent 呼叫：

```javascript
const catalog = require('./index.js');

// 新增工具
await catalog.add({
  name: 'New AI Tool',
  agent: 'claude',
  url: 'https://example.com',
  status: 'pending',
  description: 'A new tool to evaluate'
});

// 列出所有工具
const tools = await catalog.list();
console.log(tools);

// 列出特定 Agent 的工具
const claudeTools = await catalog.list({ agent: 'claude' });

// 重新生成 HTML
await catalog.regenerate();
```

### 可用的 Agent 類型

- `claude` — Claude 系列工具
- `openclaw` — OpenClaw 系列工具
- `hermes` — Hermes 系列工具
- `general` — 通用 AI 工具

### 可用的狀態

- `installed` — 已安裝 ✅
- `pending` — 待處理 ⏳
- `evaluating` — 待評估 🔍
- `unavailable` — 無法使用 ❌

## 📋 Catalog 格式說明

`ai-tools-catalog.md` 使用 Markdown 表格格式，每個欄位說明如下：

| 欄位 | 說明 | 範例 |
|------|------|------|
| 名稱 | 工具顯示名稱 | Claude Desktop |
| Agent | 所屬 Agent 類型 | claude / openclaw / hermes / general |
| URL | 工具官網或 GitHub 連結 | https://claude.ai/desktop |
| 狀態 | 安裝狀態 | ✅ / ⏳ / 🔍 / ❌ |
| 說明 | 簡短描述 | Anthropic 出品的 AI 助手 |

### 狀態圖示對照

- ✅ — `installed` — 已安裝並可正常使用
- ⏳ — `pending` — 排程中，待處理
- 🔍 — `evaluating` — 正在評估或測試中
- ❌ — `unavailable` — 無法使用（版本過舊、相容性問題等）

## 🔄 自動更新機制

本專案利用 macOS launchd 的 `WatchPaths` 功能監聽 `ai-tools-catalog.md` 的變更：

1. 當 `catalog.md` 被修改（無論是手動編輯或透過 `catalog-add.sh`）
2. launchd 自動觸發 `bin/generate.py`
3. Python 腳本重新解析 Markdown 並生成最新的 HTML
4. 重新整理瀏覽器即可看到更新後的目錄

### launchd 設定檔說明

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ai-catalog.watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/path/to/ai-catalog/bin/generate.py</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/path/to/ai-catalog/ai-tools-catalog.md</string>
    </array>
</dict>
</plist>
```

## 🤝 貢獻方式

歡迎提出 Issue 或提交 Pull Request！

1. **回報問題** — 透過 GitHub Issue 回報錯誤或建議功能
2. **新增工具** — 使用 `catalog-add.sh` 或直接編輯 `catalog.md`
3. **改進程式碼** — 歡迎提交 PR 改善 `generate.py` 或 `index.js`

## 📄 授權

本專案採用 MIT License — 詳見 [LICENSE](LICENSE) 檔案。