#!/bin/bash
# catalog-add.sh — 新增工具到 ai-tools-catalog.md 並重新生成 HTML
# 用法: catalog-add.sh "工具名" "Agent關鍵字" "子分類關鍵字" "狀態" "特色" ["費用"] ["備註"]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CATALOG="${CATALOG:-$HOME/skill-hub/ai-tools-catalog.md}"
GENERATE="${GENERATE:-$SCRIPT_DIR/generate.py}"

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

if [[ ! -f "$CATALOG" ]]; then
  echo "❌ 目錄檔不存在：$CATALOG" >&2
  exit 1
fi
if [[ ! -w "$CATALOG" ]]; then
  echo "❌ 目錄檔不可寫入：$CATALOG" >&2
  exit 1
fi

# 以 Python 處理 Unicode 標題與插入點：接受前後空白、全形 # 與 emoji，
# 並在缺少檔尾換行時補上，避免新增列黏到下一個標題。
python3 - "$CATALOG" "$AGENT_KEY" "$SECTION_KEY" "$TOOL_NAME" "$STATUS" "$FEATURE" "$COST" "$NOTE" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
agent_key, section_key, tool, status, feature, cost, note = sys.argv[2:]
heading_re = re.compile(r"^\s*([#＃]{2,3})\s*(.*?)\s*$")

def heading(line):
    match = heading_re.match(line.rstrip("\r\n"))
    if not match:
        return None
    marks, title = match.groups()
    if len(marks) not in (2, 3):
        return None
    return len(marks), title.strip()

try:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
except OSError as exc:
    raise SystemExit(f"❌ 無法讀取目錄檔：{exc}")

agent_index = next((i for i, line in enumerate(lines)
                    if (item := heading(line)) and item[0] == 2 and agent_key.casefold() in item[1].casefold()), None)
if agent_index is None:
    raise SystemExit(f"❌ 找不到 Agent：{agent_key}")

section_index = None
for i in range(agent_index + 1, len(lines)):
    item = heading(lines[i])
    if item and item[0] <= 2:
        break
    if item and item[0] == 3 and section_key.casefold() in item[1].casefold():
        section_index = i
        break
if section_index is None:
    raise SystemExit(f"❌ 找不到子分類：{section_key}（在 Agent: {heading(lines[agent_index])[1]} 下）")

section_end = len(lines)
for i in range(section_index + 1, len(lines)):
    item = heading(lines[i])
    if item and item[0] <= 3:
        section_end = i
        break
    if lines[i].strip() == "---":
        section_end = i
        break

header_index = next((i for i in range(section_index + 1, section_end)
                     if lines[i].lstrip().startswith("|") and "工具" in lines[i]), None)
if header_index is None:
    raise SystemExit("❌ 找不到表格標頭")
column_count = lines[header_index].count("|") - 1
if column_count < 4:
    raise SystemExit(f"❌ 表格欄位不足：{column_count}")

last_row = None
for i in range(header_index + 1, section_end):
    stripped = lines[i].strip()
    if stripped.startswith("|") and not re.fullmatch(r"\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?", stripped):
        last_row = i
if last_row is None:
    raise SystemExit("❌ 找不到表格資料列")

if column_count >= 6:
    row = f"| **{tool}** | {status} | {feature} | {cost} | ❓ | {note} |"
elif column_count >= 5:
    row = f"| **{tool}** | {status} | {feature} | {cost} | {note} |"
else:
    row = f"| **{tool}** | {status} | {feature} | {note} |"

if not lines[last_row].endswith(("\n", "\r")):
    lines[last_row] += "\n"
lines.insert(last_row + 1, row + "\n")
try:
    path.write_text("".join(lines), encoding="utf-8")
    if row not in path.read_text(encoding="utf-8"):
        raise OSError("寫入後重新讀取找不到新增列")
except OSError as exc:
    raise SystemExit(f"❌ 寫入目錄失敗：{exc}")

print(f"✅ 已新增：{tool} → {heading(lines[agent_index])[1]} / {heading(lines[section_index])[1]}")
PY
if [[ $? -ne 0 ]]; then
  exit 1
fi

if [[ ! -f "$GENERATE" ]]; then
  echo "❌ 找不到 generate.py：$GENERATE" >&2
  exit 1
fi
if ! python3 "$GENERATE"; then
  echo "❌ HTML 更新失敗" >&2
  exit 1
fi
echo "✅ HTML 已更新"
