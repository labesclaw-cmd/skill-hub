#!/bin/bash
# daily_report.sh — 每日任務報告：18:30 自動生成 + 儲存桌面 + 發信

DATE=$(date +%Y-%m-%d)
TIME=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_PATH="$HOME/Desktop/今日報告-${DATE}.md"
SEND_PATH="/tmp/今日報告-${DATE}.md"
LOG="$HOME/.claude/daily_report.log"
TODAY=$(date +%Y-%m-%d)
LAST_RUN_FLAG="$HOME/.claude/daily_report_last_run"

echo "[$TIME] 開始生成今日報告..." >> "$LOG"

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

[ -z "$TASKS_DONE" ]   && TASKS_DONE="（今日無已完成任務記錄）"
[ -z "$TASKS_PENDING" ] && TASKS_PENDING="（無待辦任務，或 TASKS.md 未找到）"

# ── 2. 掃描今日新增/修改的 skill 與腳本 ──────────────────────────
SKILLS_DIR="$HOME/.openclaw/workspace/skills"
CLAUDE_DIR="$HOME/.claude"
SKILL_HUB="$HOME/skill-hub"

# 用 last_run flag 做基準；第一次執行改用當天凌晨
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

    # 針對每個 .sh / .py 抽取說明行
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
        lines.append(f'- 📧 **{subject}**  ·  寄件人：{sender}')

print('\n'.join(lines) if lines else '（今日無新信件）')
PYEOF
    )
fi

# ── 4. 明日建議 ───────────────────────────────────────────────────
TOMORROW_PLAN=$(echo "$TASKS_PENDING" | grep "^- ⏳" | head -3 \
    | sed 's/^- ⏳ /- 🔜 /')
[ -z "$TOMORROW_PLAN" ] && TOMORROW_PLAN="- 🔜 依最新 TASKS.md 規劃，無自動建議"

# ── 5. 組合報告 ───────────────────────────────────────────────────
cat > "$REPORT_PATH" << MDEOF
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

echo "[$TIME] 報告已儲存：$REPORT_PATH" >> "$LOG"

# ── 6. 發信（附件）───────────────────────────────────────────────
cp "$REPORT_PATH" "$SEND_PATH"

python3 - "$SEND_PATH" "$DATE" << 'PYEOF'
import json, urllib.request, urllib.parse, base64, sys
import email.mime.multipart, email.mime.text, email.mime.base, email.encoders

send_path = sys.argv[1]
date_str  = sys.argv[2]

def get_token():
    with open('$HOME/.claude/gmail_token.json') as f:
        token = json.load(f)
    with open('$HOME/.claude/gmail_client_secret.json') as f:
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

msg = email.mime.multipart.MIMEMultipart()
import os
notify_email = os.environ.get('NOTIFY_EMAIL', '')
if not notify_email:
    cfg = os.path.expanduser('~/.claude/notify_config.sh')
    if os.path.exists(cfg):
        for line in open(cfg):
            if 'NOTIFY_EMAIL' in line:
                notify_email = line.split('=',1)[-1].strip().strip('"').strip("'")
msg['To']      = notify_email
msg['Subject'] = f'Claude 每日任務報告 — {date_str}'
msg['From']    = 'me'

body = f'今日任務報告請見附件。\n報告亦儲存於桌面：今日報告-{date_str}.md'
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
print('郵件寄出成功，ID:', resp.get('id', '?'))
PYEOF

echo "[$TIME] 報告已發信" >> "$LOG"
rm -f "$SEND_PATH"
