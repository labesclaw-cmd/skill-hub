#!/bin/bash
# auto-publish.sh — 偵測 catalog 變更後自動 commit + push 到 GitHub
# 由 launchd WatchPaths 觸發，或手動執行

set -e

CATALOG_DIR="$HOME/skill-hub/ai-catalog"
CATALOG_FILE="$HOME/skill-hub/ai-tools-catalog.md"
GENERATE="$CATALOG_DIR/bin/generate.py"
LOG="/tmp/ai-catalog-publish.log"
SCREENSHOT_OUT="$CATALOG_DIR/docs/screenshot.png"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] auto-publish 觸發" >> "$LOG"

# 重新生成 HTML
python3 "$GENERATE" >> "$LOG" 2>&1

# 更新截圖
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --headless=new --disable-gpu \
  --screenshot="$SCREENSHOT_OUT" \
  --window-size=1400,900 \
  "file://$HOME/Desktop/AI工具目錄.html" 2>/dev/null && \
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 截圖已更新" >> "$LOG"

# Git commit + push（只有在有變更時）
cd "$HOME/skill-hub"
git add ai-catalog/ ai-tools-catalog.md 2>/dev/null

if git diff --cached --quiet; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 無變更，略過 commit" >> "$LOG"
  exit 0
fi

CHANGED_TOOLS=$(git diff --cached --name-only | tr '\n' ', ' | sed 's/,$//')
git commit -m "auto: update catalog [$(date '+%Y-%m-%d %H:%M')]" >> "$LOG" 2>&1
git push origin main >> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 已推送：$CHANGED_TOOLS" >> "$LOG"
