#!/bin/bash
# catalog-add.sh — 快速新增工具到 ai-tools-catalog.md 並重新生成 HTML
# 用法: catalog-add.sh "工具名" "分類" "狀態" "特色" "費用" "備註"

CATALOG="$HOME/skill-hub/ai-tools-catalog.md"
GENERATE="$HOME/skill-hub/ai-catalog/bin/generate.py"

show_usage() {
  echo "用法: catalog-add.sh <工具名> <分類關鍵字> <狀態> <特色> [費用] [備註]"
  echo ""
  echo "狀態選項:"
  echo "  installed  → ✅ 已安裝"
  echo "  pending    → ⏳ 待處理"
  echo "  review     → 🔍 待評估"
  echo "  blocked    → ❌ 無法使用"
  echo ""
  echo "分類關鍵字（部分符合即可）:"
  grep "^## " "$CATALOG" | sed 's/## /  /'
  echo ""
  echo "範例:"
  echo "  catalog-add.sh \"Midjourney\" \"圖像\" \"pending\" \"AI圖像生成\" \"\$10/月\" \"需Discord\""
}

if [[ $# -lt 4 ]]; then
  show_usage
  exit 1
fi

TOOL_NAME="$1"
CATEGORY_KEY="$2"
STATUS_KEY="$3"
FEATURE="$4"
COST="${5:-}"
NOTE="${6:-}"

case "$STATUS_KEY" in
  installed) STATUS="✅ 已安裝" ;;
  pending)   STATUS="⏳ 待處理" ;;
  review)    STATUS="🔍 待評估" ;;
  blocked)   STATUS="❌ 無法使用" ;;
  *)         STATUS="$STATUS_KEY" ;;
esac

# 找到目標分類的最後一個表格行位置
SECTION_LINE=$(grep -n "## .*${CATEGORY_KEY}" "$CATALOG" | head -1 | cut -d: -f1)

if [[ -z "$SECTION_LINE" ]]; then
  echo "❌ 找不到分類：$CATEGORY_KEY"
  echo "可用分類："
  grep "^## " "$CATALOG"
  exit 1
fi

# 找到此分類後的第一個 --- 分隔線（即本分類結束位置）
END_LINE=$(awk "NR>$SECTION_LINE && /^---/{print NR; exit}" "$CATALOG")
if [[ -z "$END_LINE" ]]; then
  END_LINE=$(wc -l < "$CATALOG")
fi

# 找到此分類最後一個表格資料行
LAST_TABLE_LINE=$(awk "NR>$SECTION_LINE && NR<$END_LINE && /^\|[^-]/{last=NR} END{print last+0}" "$CATALOG")

if [[ "$LAST_TABLE_LINE" -eq 0 ]]; then
  echo "❌ 找不到表格位置"
  exit 1
fi

# 決定欄位數量（看標題行有幾欄）
HEADER_LINE=$(awk "NR>$SECTION_LINE && /^\| 工具/{print NR; exit}" "$CATALOG")
COL_COUNT=$(awk "NR==$HEADER_LINE{n=gsub(/\|/,\"|\"); print n-1}" "$CATALOG")

# 組合新行
if [[ "$COL_COUNT" -ge 6 ]]; then
  NEW_ROW="| **${TOOL_NAME}** | ${STATUS} | ${FEATURE} | ${COST} | ❓ | ${NOTE} |"
elif [[ "$COL_COUNT" -ge 5 ]]; then
  NEW_ROW="| **${TOOL_NAME}** | ${STATUS} | ${FEATURE} | ${COST} | ${NOTE} |"
else
  NEW_ROW="| **${TOOL_NAME}** | ${STATUS} | ${FEATURE} | ${NOTE} |"
fi

# 插入新行
sed -i '' "${LAST_TABLE_LINE}a\\
${NEW_ROW}" "$CATALOG"

echo "✅ 已新增：$TOOL_NAME → $(grep "## .*${CATEGORY_KEY}" "$CATALOG" | head -1 | sed 's/## //')"

# 重新生成 HTML
if python3 "$GENERATE" 2>/dev/null; then
  echo "✅ HTML 已更新：~/Desktop/AI工具目錄.html"
else
  echo "⚠️  HTML 更新失敗，請手動執行 generate.py"
fi
