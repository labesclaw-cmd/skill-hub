# AI 工具目錄
> 我的 AI 工具清單，依 Agent 分類管理，持續更新。

---

## 🖥️ Claude

### 🛠️ MCP 工具

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **github MCP** | ✅ 已安裝 | GitHub repo 操作 | 免費 | |
| **puppeteer MCP** | ✅ 已安裝 | 瀏覽器自動化 | 免費 | |
| **filesystem MCP** | ✅ 已安裝 | 本機檔案系統存取 | 免費 | |
| **context7 MCP** | ✅ 已安裝 | 即時文件查詢 | 免費 | |
| **chrome-devtools MCP** | ✅ 已安裝 | Chrome 瀏覽器控制 v0.21.0 | 免費 | |
| **Claude.ai /mcp-builder** | ⏳ 待處理 | 建立 MCP Server 的 Skill，Python/Node 皆支援 | 免費 | 需在 claude.ai Cowork 安裝 |
### 🧠 Skill Hub

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **ai-catalog** | ✅ 已安裝 | AI 工具目錄 HTML 查閱 | 免費 | ~/skill-hub/ai-catalog/ |
| **hermes_task.sh** | ✅ 已安裝 | Claude Code 呼叫 Hermes 輕量任務腳本 | 免費 | ~/cowork/scripts/ |
| **notebooklm-py** | ✅ 已安裝 | NotebookLM 非官方 Python API + Claude Code Skill，可程式化操作 notebook、生成 podcast/影片/測驗，支援批次下載等 Web UI 沒有的功能 | 免費/開源 | MIT，v0.3.4，~/.venv/notebooklm，skill 已安裝 |
| **Claude.ai 畫布設計** | ⏳ 待處理 | 生成 PNG/PDF 視覺設計，海報/UI草稿/縮圖 | 免費 | 需在 claude.ai Cowork 安裝 |
| **Claude.ai Brightdata插件** | ⏳ 待處理 | 40+網站爬蟲（YouTube/Amazon/TikTok），機器人繞過 | freemium | 大量爬蟲需付費 |## 🌐 通用工具
| **Claude.ai Postiz** | ⏳ 待處理 | 28+平台社群排程（YouTube/TikTok/Instagram等） | freemium | 需各平台 API Key |
| **Claude.ai Searchfit SEO** | ⏳ 待處理 | 免費SEO工具組：審核、關鍵字、AI效果追蹤 | 免費 | 適合 YouTube SEO 使用 |### 💻 本地推理

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **Ollama** | ✅ 已安裝 | 本地 LLM 推理，支援 gemma4:26b / qwen3:8b | 免費 | localhost:11434，OpenAI-compatible |
| **Rapid-MLX** | ✅ 已安裝 | Apple Silicon 本地 LLM 推理，基於 MLX 框架，OpenAI-compatible API，比 Ollama 快 2-4x | 免費/開源 | v0.6.11，brew 安裝，qwen3.5-4b 已下載（168 tok/s），port 11435 |
| **skilless.ai** | ✅ 已安裝 | 給 Claude Code 加上網頁搜尋、yt-dlp 字幕提取、RSS 解析能力 | 免費 | 一行安裝，已連結 ~/.claude/skills/ |
### 🎬 影片生成

| 工具 | 狀態 | 特色 | 費用 | 備註 |
| **CapCut 剪映 Pro** | 🔍 待評估 | 一站式 AI 影片:AI配音、數位人avatar、字幕、剪輯、去背、縮圖;中文原生字節跳動;Web版可免費試做 | NT290月 或 NT2490年;Web免費可試 | 風管YouTube主力候選;先免費試做驗證中文專有名詞發音 ||------|------|------|------|------|
| **HeyGen** | 🔍 待評估 | 高擬真AI主播Avatar IV;175語言對嘴;有API可全自動化;約30分鐘月 | US29月 年繳US24 | 風管YouTube升級選項;有API我可串接自動產片 |
| **Kling 3.0** | 🔍 待評估 | 圖或文字生角色;Subject Binding 跨鏡角色一致性最強5分;單段最長15秒;無中文配音需配HeyGen | 免費66credits日;Standard US6.99月年繳 | AI短劇方案A核心影片生成;台灣信用卡可付 |### 🖼️ 圖像生成

| 工具 | 狀態 | 特色 | 費用 | 備註 |
| **Domo AI** | 🔍 待評估 | 上傳角色圖轉動畫Character-to-Video;動漫風格最佳;無中文配音無腳本流;真人感較弱 | Basic US6.99月年繳500credits | James指定納入;動漫短劇適用真人較弱 ||------|------|------|------|------|
| **Vidu** | 🔍 待評估 | 多參考圖最多7張角色一致;Reference-to-Video;每段5-8秒;有API | 免費800credits月離峰無限;Standard US10月 | AI短劇方案B角色一致補充;Stripe付款 |
| **LTX Studio** | 🔍 待評估 | 最完整腳本到分鏡到影片流程;Elements角色場景庫跨鏡一致;個人無API | 免費800credits一次;Standard US28月年繳 | AI短劇方案B一站式腳本流 |### 📓 知識整理

| 工具 | 狀態 | 特色 | 費用 | 備註 |
| **markitdown** | ✅ 已安裝 | 微軟開源，把PDF/Office/影像/音訊/YouTube/網址等轉成Markdown供LLM讀取 | 免費開源MIT；選用Azure/LLM圖片描述功能才計費 | venv裝於~/cowork/tools/markitdown-venv，alias mid；YouTube抓現成字幕不跑whisper ||------|------|------|------|------|

---

## 狀態說明
- ✅ 已安裝/可用
- ⏳ 規劃中/待申請/待設定
- 🔍 待評估
- ❌ 無法使用

---
*最後更新：2026-05-06*
