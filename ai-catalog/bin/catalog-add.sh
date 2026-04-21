#!/bin/bash
# catalog-add.sh — 新增工具到 ai-tools-catalog.md 並重新生成 HTML
# 用法: catalog-add.sh "工具名" "Agent關鍵字" "子分類關鍵字" "狀態" "特色" ["費用"] ["備註"]

CATALOG="$HOME/skill-hub/ai-tools-catalog.md"
GENERATE="$HOME/skill-hub/ai-catalog/bin/generate.py"

show_usage() {
  echo "用法: catalog-add.sh <工具名> <Agent關鍵字> <子分類關鍵字> <狀態> <特色> [費用] [備註]"
  echo ""
  echo "Agent 關鍵字（部分符合）:"
  grep "^## " "$CATALOG" | grep -v "狀態" | sed 's/## /  /'
  echo ""
  echo "子分類關鍵字（部分符合）:"
  grep "^### " "$CATALOG" | sed 's/### /  /'
  echo ""
  echo "狀態: installed / pending / review / blocked"
  echo ""
  echo "範例:"
  echo "  catalog-add.sh \"Midjourney\" \"通用\" \"圖像\" \"pending\" \"AI圖像生成\" \"\$10/月\" \"需Discord\""
  echo "  catalog-add.sh \"n8n Skill\" \"OpenClaw\" \"自動化\" \"pending\" \"工作流節點\" \"免費\" \"\""
}

if [[ $# -lt 5 ]]; then
  show_usage
  exit 1
fi

TOOL_NAME="$1"
AGENT_KEY="$2"
SECTION_KEY="$3"
STATUS_KEY="$4"
FEATURE="$5"
COST="${6:-}"
NOTE="${7:-}"

case "$STATUS_KEY" in
  installed) STATUS="✅ 已安裝" ;;
  pending)   STATUS="⏳ 待處理" ;;
  review)    STATUS="🔍 待評估" ;;
  blocked)   STATUS="❌ 無法使用" ;;
  *)         STATUS="$STATUS_KEY" ;;
esac

# 找到 Agent 區塊
AGENT_LINE=$(grep -in "^## .*${AGENT_KEY}" "$CATALOG" | head -1 | cut -d: -f1)
if [[ -z "$AGENT_LINE" ]]; then
  echo "❌ 找不到 Agent：$AGENT_KEY"
  grep "^## " "$CATALOG" | grep -v "狀態"
  exit 1
fi

# 找到 Agent 下的子分類
SECTION_LINE=$(awk "NR>$AGENT_LINE && /^### .*${SECTION_KEY}/{print NR; exit}" "$CATALOG")
if [[ -z "$SECTION_LINE" ]]; then
  echo "❌ 找不到子分類：$SECTION_KEY（在 Agent: $AGENT_KEY 下）"
  awk "NR>$AGENT_LINE && /^### /{print}" "$CATALOG"
  exit 1
fi

# 找到下一個 ## 或 ### 作為此子分類的結束
NEXT_SECTION=$(awk "NR>$SECTION_LINE && /^(##|---$)/{print NR; exit}" "$CATALOG")
[[ -z "$NEXT_SECTION" ]] && NEXT_SECTION=$(wc -l < "$CATALOG")

# 找到此子分類最後一個表格資料行
LAST_TABLE=$(awk "NR>$SECTION_LINE && NR<$NEXT_SECTION && /^\|[^-]/{last=NR} END{print last+0}" "$CATALOG")

if [[ "$LAST_TABLE" -eq 0 ]]; then
  echo "❌ 找不到表格位置"
  exit 1
fi

# 偵測欄位數
HEADER_LINE=$(awk "NR>$SECTION_LINE && /^\| 工具/{print NR; exit}" "$CATALOG")
COL_COUNT=$(awk "NR==$HEADER_LINE{n=gsub(/\|/,\"|\"); print n-1}" "$CATALOG")

if [[ "$COL_COUNT" -ge 6 ]]; then
  NEW_ROW="| **${TOOL_NAME}** | ${STATUS} | ${FEATURE} | ${COST} | ❓ | ${NOTE} |"
elif [[ "$COL_COUNT" -ge 5 ]]; then
  NEW_ROW="| **${TOOL_NAME}** | ${STATUS} | ${FEATURE} | ${COST} | ${NOTE} |"
else
  NEW_ROW="| **${TOOL_NAME}** | ${STATUS} | ${FEATURE} | ${NOTE} |"
fi

sed -i '' "${LAST_TABLE}a\\
${NEW_ROW}" "$CATALOG"

AGENT_TITLE=$(awk "NR==$AGENT_LINE{print}" "$CATALOG" | sed 's/## //')
SECTION_TITLE=$(awk "NR==$SECTION_LINE{print}" "$CATALOG" | sed 's/### //')
echo "✅ 已新增：$TOOL_NAME → $AGENT_TITLE / $SECTION_TITLE"

python3 "$GENERATE" 2>/dev/null && echo "✅ HTML 已更新" || echo "⚠️  HTML 更新失敗"
