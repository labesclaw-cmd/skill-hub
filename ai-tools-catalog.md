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
| **Claude.ai Brightdata插件** | ⏳ 待處理 | 40+網站爬蟲（YouTube/Amazon/TikTok），機器人繞過 | freemium | 大量爬蟲需付費 |
| **text-to-cad** | 🔍 待評估 | 用講的叫 agent 寫 build123d/OpenCASCADE 程式出 STEP/STL/3MF/GLB，含製造檢查、工程圖（GitHub earthtojake/text-to-cad，2.3萬星） | 免費（MIT） | 10/26 James 傳 FB；可接 CAD轉3D 專案（退路本來就是 OCCT）；裝了要 uvx cadgen telemetry off |
| **Graphify** | ✅ 已安裝 | 把程式碼庫建成知識圖譜，給 Claude 查程式結構 | 免費 | 10/26 上線每晚 03:30 graphify-nightly：~/cowork/scripts/graphify-out、~/projects/AI_Drama/tools/graphify-out |

## 🌐 通用工具
| **Claude.ai Postiz** | ⏳ 待處理 | 28+平台社群排程（YouTube/TikTok/Instagram等） | freemium | 需各平台 API Key |
| **Claude.ai Searchfit SEO** | ⏳ 待處理 | 免費SEO工具組：審核、關鍵字、AI效果追蹤 | 免費 | 適合 YouTube SEO 使用 |

### 💻 本地推理

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **Ollama** | ✅ 已安裝 | 本地 LLM 推理，支援 gemma4:26b / qwen3:8b | 免費 | localhost:11434，OpenAI-compatible |
| **Rapid-MLX** | ✅ 已安裝 | Apple Silicon 本地 LLM 推理，基於 MLX 框架，OpenAI-compatible API，比 Ollama 快 2-4x | 免費/開源 | v0.6.11，brew 安裝，qwen3.5-4b 已下載（168 tok/s），port 11435 |
| **skilless.ai** | ✅ 已安裝 | 給 Claude Code 加上網頁搜尋、yt-dlp 字幕提取、RSS 解析能力 | 免費 | 一行安裝，已連結 ~/.claude/skills/ |
| **notebooklm-py** | ✅ 已安裝 | 程式化操作 NotebookLM（list/ask/source add），讓 Claude 直接讀 James 的 YouTube 分析筆記本 | 免費 | 非官方 API；2026-10-02 登入過期需重登；帳號待 James 確認（chenyuchi09 需明確授權） |
| **gpu-unlock (Zagitta)** | 🔍 待評估 | 解開 RTX 30 系家用卡 Tensor 核心 FP16/BF16 累加限速（3060 回報矩陣運算約 +80%）；只支援 Linux，Windows 為第三方 UEFI 分支 impacifist/Windows-GPU-UNLOCK | 免費 | 10/26 評估暫緩：桌機要關 Secure Boot、改開機鏈，遠端開不了機無人救；H3 是 INT8 可能不受惠；10/28 看 H3 加速節點結果再評（fu-175424d310e2） |

### 🎬 影片生成

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **CapCut 剪映 Pro** | 🔍 待評估 | 一站式 AI 影片:AI配音、數位人avatar、字幕、剪輯、去背、縮圖;中文原生字節跳動;Web版可免費試做 | NT290月 或 NT2490年;Web免費可試 | 風管YouTube主力候選;先免費試做驗證中文專有名詞發音 |
| **HeyGen** | 🔍 待評估 | 高擬真AI主播Avatar IV;175語言對嘴;有API可全自動化;約30分鐘月 | US29月 年繳US24 | 風管YouTube升級選項;有API我可串接自動產片 |
| **Kling 3.0** | 🔍 待評估 | 圖或文字生角色;Subject Binding 跨鏡角色一致性最強5分;單段最長15秒;無中文配音需配HeyGen | 免費66credits日;Standard US6.99月年繳 | AI短劇方案A核心影片生成;台灣信用卡可付 |
| **ComfyUI-MiniMaxH3Mod（H3 RefMod）** | ⏳ 待處理 | H3 免訓練角色參考：8 張多角度圖→約1MB refmod 檔，像 LoRA 一樣載入，可同時掛多角色，解雙女主混臉 | 免費（MIT） | github.com/Luisacaotica/ComfyUI-MiniMaxH3Mod；EP01 v3 拍完後裝桌機測 |
| **MiniMax H3 Singularity ref2va v1.3** | 🔍 待評估 | 社群微調版 H3 參考生成模型；影片作者用 euler＋beta 取樣、Sage＋稀疏注意力加速 | 免費 | 10/26 解析 YT；與官方 ref2va 對照測試排在 EP01 v3 後 |

### 🖼️ 圖像生成

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **Domo AI** | 🔍 待評估 | 上傳角色圖轉動畫Character-to-Video;動漫風格最佳;無中文配音無腳本流;真人感較弱 | Basic US6.99月年繳500credits | James指定納入;動漫短劇適用真人較弱 |
| **Vidu** | 🔍 待評估 | 多參考圖最多7張角色一致;Reference-to-Video;每段5-8秒;有API | 免費800credits月離峰無限;Standard US10月 | AI短劇方案B角色一致補充;Stripe付款 |
| **LTX Studio** | 🔍 待評估 | 最完整腳本到分鏡到影片流程;Elements角色場景庫跨鏡一致;個人無API | 免費800credits一次;Standard US28月年繳 | AI短劇方案B一站式腳本流 |
| **Qwen-Image-Edit-2511 多角度 LoRA** | 🔍 待評估 | ComfyUI 相機控制（水平角／俯仰角／距離），一張乾淨場景圖轉出其他機位，同一場景多角度一致 | 免費（桌機跑） | 10/26 James 核准；已下載 E:\Claude\models\loras；輸出 1536x864 要再放大 |
| **SeedVR2 放大工作流** | ⏳ 待處理 | ComfyUI 參考圖精細放大（補髮絲睫毛細節），參考圖越清楚影片越好 | 免費（桌機跑） | 10/26 James 核准；節點暫存 E:\Claude\dl，EP01 v3 拍完後裝（fu-da3786bbbd13）；12GB 選 3B GGUF＋blockswap |

### 📓 知識整理

| 工具 | 狀態 | 特色 | 費用 | 備註 |
|------|------|------|------|------|
| **markitdown** | ✅ 已安裝 | 微軟開源，把PDF/Office/影像/音訊/YouTube/網址等轉成Markdown供LLM讀取 | 免費開源MIT；選用Azure/LLM圖片描述功能才計費 | venv裝於~/cowork/tools/markitdown-venv，alias mid；YouTube抓現成字幕不跑whisper |
| **Claude Duet** | 🔍 待評估 | Anthropic 職場型 AI 代理人預覽版（官方產品，非 skill）：每日摘要、追蹤已連結 App、建儀表板、排會議、財務預測；主動提醒、離線續跑、行動前先確認 | Pro/Max 訂閱內（候補名單） | 2026-10-21 發布，獨立 App＋網站；競品 Meta Muse、OpenAI Dots；來源鉅亨 6635482 |
| **NVIDIA USD BRep（SMLib）** | 🔍 待評估 | NVIDIA 開源的工業級 CAD 實體幾何核心（B-Rep/NURBS、布林運算、掃掠、質量計算，C++/Python，可匯出 STEP/OpenUSD），讓 AI 用程式碼直接建精確實體 | 免費（Apache 2.0） | CAD轉3D 參考；10/22 James 傳 FB 彭致華影片（鋼構 3 張圖→74 構件→穿梁孔檢核→35.4 噸） |

---

## 狀態說明
- ✅ 已安裝/可用
- ⏳ 規劃中/待申請/待設定
- 🔍 待評估
- ❌ 無法使用

---
*最後更新：2026-10-26*
