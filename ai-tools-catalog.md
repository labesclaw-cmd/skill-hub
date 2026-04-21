# AI 工具總覽目錄
> 持續更新。依 Agent 分類整理所有評估過的 AI 工具與技能。

---

## 🖥️ Claude

### 🛠️ MCP 工具

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **GitHub MCP** | ✅ 已安裝 | 操作 GitHub repo | 免費 | |
| **Puppeteer MCP** | ✅ 已安裝 | 無頭瀏覽器控制 | 免費 | |
| **Filesystem MCP** | ✅ 已安裝 | 本地檔案存取 | 免費 | |
| **Context7 MCP** | ✅ 已安裝 | 查詢最新技術文件 | 免費 | |
| **Chrome DevTools MCP** | ✅ 已安裝 | 控制正在開著的 Chrome | 免費 | 需先開 Chrome debug port |
| **Supabase MCP** | ⏳ 待設定 | 後端資料庫 | 免費方案 | 需申請帳號 |
| **Cloudflare MCP** | ⏳ 待設定 | 部署管理 | 免費方案 | 需帳號認證 |
| **Replicate MCP** | ⏳ 待設定 | AI 圖片/影片生成 | 用量計費 | 需 API key |

### 📬 通訊整合

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **Gmail 收發** | ✅ 已設定 | 自動收信/發信 | 免費 | ~/.claude/gmail_*.py |
| **Telegram Bot** | ✅ 可用 | OpenClaw 通知頻道 | 免費 | |
| **Discord Bot** | 🔍 待評估 | Hermes gateway 串接 | 免費 | 任務 C 一部分 |

### 🧠 Skill Hub

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **claude-notify** | ✅ 已安裝 | PermissionRequest 延遲通知，夜間靜默 | 免費 | ~/skill-hub/claude-notify/ |
| **daily-report** | ✅ 已安裝 | 每天 18:30 生成報告寄信 | 免費 | ~/skill-hub/daily-report/ |
| **memory-manager** | ✅ 已安裝 | RAG 概念記憶管理，INDEX+archive | 免費 | ~/skill-hub/memory-manager/ |
| **ai-catalog** | ✅ 已安裝 | AI 工具目錄桌面 HTML 查閱 | 免費 | ~/skill-hub/ai-catalog/ |

---

## 🐾 OpenClaw

### 🤖 核心系統

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **OpenClaw 主程式** | ✅ 已安裝 | 多 agent 協作、Lapis 人設 | OpenRouter 費用 | Mac mini，~/.openclaw/ |
| **claude-agent** | ✅ 已安裝 | Claude Sonnet 子 agent | OpenRouter 費用 | workspace-claude-agent/ |
| **lab-agent** | ✅ 已安裝 | 實驗性 agent | OpenRouter 費用 | workspace-lab-agent/ |

### 📊 財務/數據

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **ETF 報告 Skill** | ✅ 已安裝 | KGI TOP50 財務監控 | 免費 | OpenClaw finance-agent |

### 🔄 自動化任務

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **夜間自動化** | ⏳ 規劃中 | 22:00-08:00 自動任務（任務 B） | 免費模型 | 尚未實作 |
| **gmail-processor** | ⏳ 規劃中 | YouTube 字幕→Claude 分析→回信（任務 C） | 免費 | 尚未實作 |

---

## 🐺 Hermes

### 🧠 本地模型

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **Hermes Agent** | ✅ 已安裝 | 本地 AI、無審查、自建 skill | 免費（本地） | Windows WSL2 + Gemma 26B |
| **Open WebUI** | ✅ 已安裝 | 瀏覽器操作 Ollama 模型 | 免費 | Windows，`webui` 指令啟動 |
| **gemma4:26b** | ✅ 已安裝 | 主力本地模型 | 免費 | Ollama，172.24.176.1:11434 |
| **nomic-embed-text** | ✅ 已安裝 | 本地 embedding 模型 | 免費 | Ollama |
| **qwen2.5:7b** | ⏳ 待安裝 | 輕量備用模型（任務 A） | 免費 | 尚未 pull |

### 🛠️ 工具腳本

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **ai-wrapper.sh** | ✅ 已安裝 | 強制精簡回覆前綴注入 | 免費 | ~/.hermes/ai-wrapper.sh |
| **AI-mode.bat** | ✅ 已安裝 | Windows 桌面模式切換 | 免費 | 桌面 AI-mode.bat |

---

## 🌐 通用 AI 工具

### 🎬 影片生成

| 工具 | 狀態 | 特色 | 費用 | 有 API | 備註 |
|------|------|------|------|--------|------|
| **Seedance 2.0** | ⏳ 待申請 | 寫實高品質、音頻同步、多模態輸入 | 免費試用 / $9.6/月 | ✅ | 回家後申請 BytePlus |
| **Domo AI** | ⏳ 待申請 | 動漫風格轉換、休閒模式不扣點 | $19.99/月 | ✅ | 休閒模式 = 無限生成 |
| **Lynx** | 🔍 待評估 | 免費 AI 影片生成 | 免費 | ❓ | 信件連結待分析 |
| **Claude+Remotion** | ✅ 可用 | 自動批次生產動畫影片、JSON 模板 | Claude 費用 | ✅ | 需安裝 Remotion |

### 🖼️ 圖像生成

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **Replicate** | ⏳ 待設定 | 多種圖像/影片模型 API | 用量計費 | MCP 已安裝，需 API key |

### 📓 知識整理

| 工具 | 狀態 | 特色 | 費用 | 有 API | 備註 |
|------|------|------|------|--------|------|
| **NotebookLM** | ✅ 已登入 | 多資料交叉分析、Podcast 生成 | 免費 | ❌ 無官方 API | |

### 🔄 自動化 / 工作流

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **n8n** | 🔍 待評估 | 視覺化工作流，節點式串接各服務，可串 Claude | 免費自架 | 信件連結待分析 |
---

## 狀態說明
- ✅ 已安裝/可用
- ⏳ 規劃中/待申請/待設定
- 🔍 待評估（有資料，尚未深入研究）
- ❌ 無法使用（原因標註於備註）

---
*最後更新：2026-04-21*
