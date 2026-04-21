# 每日工作日誌 — 2026-04-21

## ✅ 已完成

### 1. Windows Hermes Agent 回覆過長 → 已修正
- **問題**：Hermes 回覆動輒數十行，附大量標題與條列
- **原因**：Gemma 26B 模型本身傾向詳細回覆，SOUL.md system prompt 無效
- **修正方式**：
  1. 改寫 `~/.hermes/SOUL.md`，將精簡規則置於最頂端（ABSOLUTE RULES）
  2. 建立 `~/.hermes/ai-wrapper.sh`，自動在每個問題前加入精簡前綴規則
  3. 將 `~/.bashrc` 的 `alias ai` 改為指向 wrapper
- **結果**：測試問題「Discord bot 怎麼入門？」從原本 100+ 行縮短至 1 行

### 2. AI-mode.bat 修正完成（Windows 遊戲/AI 模式切換）
- 修正路徑錯誤、Idle Mode 多視窗問題、Status 閃退問題
- 改用 `start "Ollama" /MIN cmd /c "ollama serve"` 最小化背景執行
- 新增 AI-mode-說明.txt 到桌面（含範例版）

### 3. 每日報告排程建立
- 建立 `~/.claude/daily_report.sh`
- 設定 Mac launchd 永久排程（每天 18:30）
- 功能：生成 MD 報告到桌面 + 發信到 chenyuchi09@gmail.com

### 4. Gmail 收發功能確認正常
- 收信：gmail_poller.sh 每 5 分鐘掃描，今日共收到 9 封
- 發信：gmail_send.py 測試成功

---

## ⏳ 待處理

### 1. NotebookLM 全自動串接
- **進度**：半自動狀態（可手動加入連結，NotebookLM 可解析）
- **卡關原因**：NotebookLM 無官方 API，自動化需模擬點擊（脆弱易壞）
- **目前狀態**：你已登入 labesclaw@gmail.com，試用成功解析 YouTube 影片
- **待辦**：評估是否值得做自動化，或改用 Claude 直接分析替代

### 2. Gmail → YouTube 自動分析回信
- **進度**：計畫已建立，尚未實作
- **內容**：你寄 YouTube 連結 → Claude 自動抓字幕分析 → 回信摘要
- **待辦**：建立處理腳本，優先處理 YouTube 連結（FB 第二階段）

### 3. Hermes ↔ Claude 跨 AI 協作
- **進度**：討論階段，尚未實作
- **待辦**：確認 Hermes gateway port，建立 MCP 橋接

### 4. 天堂381私服架設
- **進度**：Step 1 確認 DB，Navicat 說明已發信
- **待辦**：繼續 Step 2

---

## 🆕 今日新增技能 / 工具

### `~/.hermes/ai-wrapper.sh`
- **用途**：自動為每個 Hermes 問題加上精簡規則前綴
- **使用方式**：直接輸入 `ai`（已取代原本的 `hermes chat`）
- **原理**：在你的問題前自動加入「【規則：最多5行，禁用標題，直接給結論】」

### `~/.claude/daily_report.sh`
- **用途**：每天 18:30 生成工作報告並發信
- **使用方式**：自動執行，無需操作。手動測試可執行 `bash ~/.claude/daily_report.sh`

### `C:\Users\win10\Desktop\AI-mode.bat`（Windows）
- **用途**：一鍵切換遊戲模式 / AI 模式
- **使用方式**：雙擊執行，選擇 [1] 遊戲模式 / [2] AI 模式 / [3] 狀態查詢
