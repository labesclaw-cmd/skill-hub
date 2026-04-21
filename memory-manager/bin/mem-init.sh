#!/bin/bash
# mem-init — 初始化記憶目錄結構，把現有 memory 遷移進來

MEMORY_DIR="$HOME/.claude/memory"
ACTIVE_DIR="$MEMORY_DIR/active"
ARCHIVE_DIR="$MEMORY_DIR/archive"
INDEX="$MEMORY_DIR/INDEX.md"
OLD_MEMORY="$HOME/.claude/projects/-Users-jamesmacmini/memory"

mkdir -p "$ACTIVE_DIR" "$ARCHIVE_DIR"

# 把現有的 project_ 和 feedback_ memory 複製到 active
if [ -d "$OLD_MEMORY" ]; then
    for f in "$OLD_MEMORY"/*.md; do
        fname=$(basename "$f")
        [ "$fname" = "MEMORY.md" ] && continue
        cp "$f" "$ACTIVE_DIR/$fname"
        echo "遷移：$fname"
    done
fi

# 建立 INDEX.md
cat > "$INDEX" << 'IDXEOF'
# Memory INDEX
> 這是輕量索引，每次 session 自動載入。需要細節時用 mem-recall.sh 抓取。

## 進行中
- `user_james.md` — James 個人檔案、溝通偏好
- `project_skill_hub.md` — skill-hub repo、三大待執行任務
- `project_hermes_windows.md` — Windows Hermes 設定狀態
- `project_gmail_auto_analysis.md` — Gmail 自動分析計畫
- `project_openclaw.md` — OpenClaw 系統概況
- `project_lineage381.md` — 天堂381私服進度

## 重要規則
- 禁用 Gemini/Google 付費 AI API
- Windows SSH 需 BOSS 明確授權
- 所有回覆用繁體中文
- session 結束前更新日誌和記憶

## 封存
（任務完成後由 mem-archive.sh 自動新增）
IDXEOF

echo "✅ 記憶系統初始化完成"
echo "📁 目錄：$MEMORY_DIR"
echo "📋 INDEX：$INDEX"
