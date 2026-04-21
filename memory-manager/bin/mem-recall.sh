#!/bin/bash
# mem-recall — 從 archive 搜尋並輸出指定記憶
# 用法: mem-recall.sh <關鍵字>

MEMORY_DIR="$HOME/.claude/memory"
ARCHIVE_DIR="$MEMORY_DIR/archive"

KEYWORD="$1"
if [ -z "$KEYWORD" ]; then
    echo "用法: mem-recall.sh <關鍵字>"
    echo "例如: mem-recall.sh hermes"
    exit 1
fi

echo "🔍 搜尋關鍵字：$KEYWORD"
echo ""

# 搜尋 archive 中符合的檔案
RESULTS=$(grep -rl "$KEYWORD" "$ARCHIVE_DIR" 2>/dev/null)

if [ -z "$RESULTS" ]; then
    echo "找不到相關記憶。"
    exit 0
fi

# 只輸出摘要區塊，不輸出原始內容（節省 token）
while IFS= read -r file; do
    echo "📄 $(basename $file)"
    sed -n '/## 摘要/,/## 原始內容/p' "$file" | grep -v "## 原始內容"
    echo ""
done <<< "$RESULTS"
