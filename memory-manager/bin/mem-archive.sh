#!/bin/bash
# mem-archive — 把 active 記憶壓縮進 archive，更新 INDEX.md
# 用法: mem-archive.sh <memory_file.md>

MEMORY_DIR="$HOME/.claude/memory"
ACTIVE_DIR="$MEMORY_DIR/active"
ARCHIVE_DIR="$MEMORY_DIR/archive"
INDEX="$MEMORY_DIR/INDEX.md"

mkdir -p "$ACTIVE_DIR" "$ARCHIVE_DIR"

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$ACTIVE_DIR/$FILE" ]; then
    echo "用法: mem-archive.sh <檔名>"
    echo "可用的 active 記憶:"
    ls "$ACTIVE_DIR/" 2>/dev/null
    exit 1
fi

BASENAME=$(basename "$FILE" .md)
TIMESTAMP=$(date '+%Y-%m-%d')
ARCHIVE_FILE="$ARCHIVE_DIR/${TIMESTAMP}_${BASENAME}.md"

# 讀取原始內容
CONTENT=$(cat "$ACTIVE_DIR/$FILE")

# 用 Claude API 壓縮成摘要（3-5行）
SUMMARY=$(python3 << PYEOF
import json, urllib.request, urllib.parse

content = open('$ACTIVE_DIR/$FILE').read()

# 用 OpenRouter 免費模型壓縮
try:
    with open('/Users/jamesmacmini/.openclaw/openclaw.json') as f:
        config = json.load(f)
    api_key = config['models']['providers']['openrouter']['apiKey']
except:
    api_key = None

if api_key:
    payload = json.dumps({
        "model": "deepseek/deepseek-r1:free",
        "messages": [{
            "role": "user",
            "content": f"請將以下記憶壓縮成 3-5 行的精簡摘要，保留關鍵事實、狀態、路徑。用繁體中文。\n\n{content}"
        }],
        "max_tokens": 200
    }).encode()
    req = urllib.request.Request(
        'https://openrouter.ai/api/v1/chat/completions',
        data=payload,
        headers={'Authorization': f'Bearer {api_key}', 'Content-Type': 'application/json'}
    )
    resp = json.loads(urllib.request.urlopen(req, timeout=30).read())
    print(resp['choices'][0]['message']['content'].strip())
else:
    # 沒有 API，直接取前5行
    lines = [l for l in content.split('\n') if l.strip() and not l.startswith('#')][:5]
    print('\n'.join(lines))
PYEOF
)

# 寫入 archive
cat > "$ARCHIVE_FILE" << MDEOF
# ${BASENAME} — 封存於 ${TIMESTAMP}

## 摘要
${SUMMARY}

## 原始內容
${CONTENT}
MDEOF

# 從 active 刪除
rm "$ACTIVE_DIR/$FILE"

# 更新 INDEX.md
python3 << PYEOF
import os, re

index_path = '$INDEX'
lines = open(index_path).readlines() if os.path.exists(index_path) else []

# 移除 active 的舊條目
lines = [l for l in lines if '${BASENAME}' not in l or 'archive' in l]

# 加入 archive 條目
archive_entry = f"- **[封存]** \`${TIMESTAMP}_${BASENAME}\` — ${SUMMARY[:60].replace(chr(10),' ')}\n"
# 找到 ## 封存 區塊插入，沒有就新增
content = ''.join(lines)
if '## 封存' not in content:
    content += '\n## 封存\n'
content += archive_entry

with open(index_path, 'w') as f:
    f.write(content)
print('INDEX.md 已更新')
PYEOF

echo "✅ 已封存：$ARCHIVE_FILE"
echo "📋 摘要：$SUMMARY"
