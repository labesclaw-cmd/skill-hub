#!/bin/bash
# daily_report.sh — 每日任務報告：18:30 自動生成 + 純 mail 發送（不存桌面）

DATE=$(date +%Y-%m-%d)
TIME=$(date '+%Y-%m-%d %H:%M:%S')
SEND_PATH="/tmp/daily_report_${DATE}.md"
LOG="$HOME/.claude/daily_report.log"
TODAY=$(date +%Y-%m-%d)
LAST_RUN_FLAG="$HOME/.claude/daily_report_last_run"

echo "[$TIME] 開始生成今日報告..." >> "$LOG"

# 載入 email 設定
[ -f "$HOME/.claude/notify_config.sh" ] && source "$HOME/.claude/notify_config.sh"
if [ -z "$NOTIFY_EMAIL" ]; then
    echo "[$TIME] ERROR: NOTIFY_EMAIL 未設定，請確認 ~/.claude/notify_config.sh" >> "$LOG"
    exit 1
fi

# ── 1. 讀取 TASKS.md ──────────────────────────────────────────────
TASKS_FILE="$HOME/.openclaw/workspace/TASKS.md"
TASKS_DONE=""
TASKS_PENDING=""

if [ -f "$TASKS_FILE" ]; then
    TASKS_DONE=$(grep -E "^\s*-\s*\[x\]" "$TASKS_FILE" | sed 's/^\s*-\s*\[x\]\s*/- ✅ /' | head -20)
    TASKS_PENDING=$(grep -E "^\s*-\s*\[\s*\]" "$TASKS_FILE" | sed 's/^\s*-\s*\[\s*\]\s*/- ⏳ /' | head -20)
fi

# 補充今日工作日誌
WORK_LOG="$HOME/.claude/daily_work_log.md"
if [ -f "$WORK_LOG" ]; then
    EXTRA_DONE=$(grep -E "^### [0-9]\." "$WORK_LOG" | sed 's/^### /- ✅ /' | head -10)
    [ -n "$EXTRA_DONE" ] && TASKS_DONE="${TASKS_DONE}
${EXTRA_DONE}"
fi

[ -z "$TASKS_DONE" ]    && TASKS_DONE="（今日無已完成任務記錄）"
[ -z "$TASKS_PENDING" ] && TASKS_PENDING="（無待辦任務，或 TASKS.md 未找到）"

# ── 2. 掃描今日新增/修改的 skill 與腳本 ──────────────────────────
SKILLS_DIR="$HOME/.openclaw/workspace/skills"
CLAUDE_DIR="$HOME/.claude"
SKILL_HUB="$HOME/skill-hub"

if [ ! -f "$LAST_RUN_FLAG" ]; then
    touch -t "$(date +%Y%m%d)0000" "$LAST_RUN_FLAG"
fi

NEW_FILES=$(find "$SKILLS_DIR" "$CLAUDE_DIR" "$SKILL_HUB" \
    -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.json" -o -name "*.md" \) \
    -newer "$LAST_RUN_FLAG" 2>/dev/null \
    | grep -v "\.git/" | grep -v "__pycache__" \
    | grep -v "gmail_inbox" | grep -v "daily_report\.log" \
    | sed "s|$HOME/||" | sort)

touch "$LAST_RUN_FLAG"

if [ -z "$NEW_FILES" ]; then
    NEW_SKILLS_LIST="（今日無新增或修改的 skill / 腳本）"
    SKILL_DETAILS=""
else
    NEW_SKILLS_LIST=$(echo "$NEW_FILES" | sed 's/^/- 📄 /')
    SKILL_DETAILS=""
    while IFS= read -r f; do
        FULL="$HOME/$f"
        [ ! -f "$FULL" ] && continue
        case "$f" in *.sh|*.py|*.js)
            DESC=$(grep "^#" "$FULL" | grep -v "^#!/" | head -3 \
                   | sed 's/^#\s*//' | tr '\n' '；' | sed 's/；$//')
            if [ -n "$DESC" ]; then
                SKILL_DETAILS="${SKILL_DETAILS}
#### \`~/$f\`
> $DESC
"
            fi
        esac
    done <<< "$NEW_FILES"
    [ -z "$SKILL_DETAILS" ] && SKILL_DETAILS="（自動說明擷取無結果，請手動查閱）"
fi

# ── 3. 今日收到的信件 ─────────────────────────────────────────────
INBOX="$HOME/.claude/gmail_inbox_new.json"
MAIL_LIST="（今日無新信件，或 inbox 檔案不存在）"

if [ -f "$INBOX" ]; then
    MAIL_LIST=$(python3 - "$INBOX" "$TODAY" << 'PYEOF'
import json, sys

inbox_path = sys.argv[1]
today      = sys.argv[2]

with open(inbox_path) as f:
    mails = json.load(f)

lines = []
for m in mails:
    date_str = m.get('date', '')
    subject  = m.get('subject', '（無主旨）')
    sender   = m.get('from', '?')
    if today in date_str or not date_str:
        lines.append(f'- 📧 {subject}  （{sender}）')

print('\n'.join(lines) if lines else '（今日無新信件）')
PYEOF
    )
fi

# ── 4. 明日建議 ───────────────────────────────────────────────────
TOMORROW_PLAN=$(echo "$TASKS_PENDING" | grep "^- ⏳" | head -3 \
    | sed 's/^- ⏳ /- 🔜 /')
[ -z "$TOMORROW_PLAN" ] && TOMORROW_PLAN="- 🔜 依最新 TASKS.md 規劃，無自動建議"

# ── 5. 組合報告到暫存檔（發完即刪）──────────────────────────────
cat > "$SEND_PATH" << MDEOF
# 今日任務報告 — ${DATE}

> 自動生成時間：${TIME}

---

## ✅ 已完成的任務

${TASKS_DONE}

---

## ⏳ 未完成的任務

${TASKS_PENDING}

---

## 🆕 新增的技能 / 工具

${NEW_SKILLS_LIST}

### 操作說明

${SKILL_DETAILS}

---

## 📬 今日收到的信件

${MAIL_LIST}

---

## 📝 明日建議

${TOMORROW_PLAN}

---
*本報告由 Claude 自動生成 · 資料來源：TASKS.md、gmail\_inbox\_new.json、skill 目錄掃描*
MDEOF

# ── 6. 統計摘要（供 mail body 用）────────────────────────────────
DONE_COUNT=$(echo "$TASKS_DONE" | grep -c "^- ✅" 2>/dev/null || echo 0)
PENDING_COUNT=$(echo "$TASKS_PENDING" | grep -c "^- ⏳" 2>/dev/null || echo 0)
NEW_COUNT=$([ -n "$NEW_FILES" ] && echo "$NEW_FILES" | wc -l | tr -d ' ' || echo 0)
MAIL_COUNT=$(echo "$MAIL_LIST" | grep -c "^- 📧" 2>/dev/null || echo 0)

# ── 7. 發信（簡短 body + .md 附件）──────────────────────────────
python3 - "$SEND_PATH" "$DATE" "$NOTIFY_EMAIL" \
    "$DONE_COUNT" "$PENDING_COUNT" "$NEW_COUNT" "$MAIL_COUNT" << 'PYEOF'
import json, urllib.request, urllib.parse, base64, sys, os
import email.mime.multipart, email.mime.text, email.mime.base, email.encoders

send_path     = sys.argv[1]
date_str      = sys.argv[2]
to_addr       = sys.argv[3]
done_count    = sys.argv[4]
pending_count = sys.argv[5]
new_count     = sys.argv[6]
mail_count    = sys.argv[7]

home = os.path.expanduser('~')

def get_token():
    with open(f'{home}/.claude/gmail_token.json') as f:
        token = json.load(f)
    with open(f'{home}/.claude/gmail_client_secret.json') as f:
        d = json.load(f)['installed']
    data = urllib.parse.urlencode({
        'refresh_token': token['refresh_token'],
        'client_id': d['client_id'],
        'client_secret': d['client_secret'],
        'grant_type': 'refresh_token'
    }).encode()
    resp = json.loads(urllib.request.urlopen(
        urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
    ).read())
    return resp['access_token']

with open(send_path, 'rb') as f:
    file_data = f.read()

body = f"""今日報告摘要 — {date_str}

✅ 已完成：{done_count} 項
⏳ 待辦中：{pending_count} 項
🆕 新增技能/腳本：{new_count} 個
📬 今日收信：{mail_count} 封

詳細內容請下載附件 今日報告-{date_str}.md 查閱。
"""

msg = email.mime.multipart.MIMEMultipart('mixed')
msg['To']      = to_addr
msg['Subject'] = f'Claude 每日任務報告 — {date_str}'
msg['From']    = 'me'

msg.attach(email.mime.text.MIMEText(body, 'plain', 'utf-8'))

part = email.mime.base.MIMEBase('application', 'octet-stream')
part.set_payload(file_data)
email.encoders.encode_base64(part)
part.add_header('Content-Disposition', 'attachment',
                filename=('utf-8', '', f'今日報告-{date_str}.md'))
msg.attach(part)

raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
req = urllib.request.Request(
    'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
    data=json.dumps({'raw': raw}).encode(),
    headers={
        'Authorization': 'Bearer ' + get_token(),
        'Content-Type': 'application/json'
    }
)
resp = json.loads(urllib.request.urlopen(req).read())
print('sent:', resp.get('id', '?'))
PYEOF

echo "[$TIME] 報告已發信至 $NOTIFY_EMAIL" >> "$LOG"
rm -f "$SEND_PATH"
