#!/bin/bash
# 每日任務報告 — 生成 MD 並發信給 James

DATE=$(date +%Y-%m-%d)
REPORT="/tmp/今日報告-${DATE}.md"
LOG="$HOME/.claude/daily_report.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 開始生成今日報告..." >> "$LOG"

# 讀取今日工作日誌
LOG_FILE="$HOME/.claude/daily_work_log.md"
if [ -f "$LOG_FILE" ]; then
    REPORT_BODY=$(cat "$LOG_FILE")
else
    REPORT_BODY="（今日尚無工作日誌，請確認 Claude 有在維護 ~/.claude/daily_work_log.md）"
fi

# 寫入 MD 報告
cat > "$REPORT" << MDEOF
${REPORT_BODY}

---
*本報告由 Claude 自動生成於 $(date '+%Y-%m-%d %H:%M:%S')*
MDEOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] MD 報告已寫入：$REPORT" >> "$LOG"

# 發信給 James（含附件）
python3 << PYEOF
import json, urllib.request, urllib.parse, base64
import email.mime.multipart, email.mime.text, email.mime.base, email.encoders

def get_token():
    with open('/Users/jamesmacmini/.claude/gmail_token.json') as f:
        token = json.load(f)
    with open('/Users/jamesmacmini/.claude/gmail_client_secret.json') as f:
        d = json.load(f)['installed']
    data = urllib.parse.urlencode({
        'refresh_token': token['refresh_token'],
        'client_id': d['client_id'],
        'client_secret': d['client_secret'],
        'grant_type': 'refresh_token'
    }).encode()
    resp = json.loads(urllib.request.urlopen(urllib.request.Request('https://oauth2.googleapis.com/token', data=data)).read())
    return resp['access_token']

report_path = '$REPORT'
date_str = '$DATE'

with open(report_path, 'rb') as f:
    file_data = f.read()

msg = email.mime.multipart.MIMEMultipart()
msg['To'] = 'chenyuchi09@gmail.com'
msg['Subject'] = f'Claude 每日工作報告 — {date_str}'
msg['From'] = 'me'

# 信件本文
msg.attach(email.mime.text.MIMEText('今日工作報告請見附件。', 'plain', 'utf-8'))

# 附加 .md 檔案
part = email.mime.base.MIMEBase('application', 'octet-stream')
part.set_payload(file_data)
email.encoders.encode_base64(part)
from email.header import Header
filename = f'Claude每日報告-{date_str}.md'
part.add_header('Content-Disposition', 'attachment', filename=('utf-8', '', filename))
msg.attach(part)

raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
payload = json.dumps({'raw': raw}).encode()
req = urllib.request.Request(
    'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
    data=payload,
    headers={'Authorization': 'Bearer ' + get_token(), 'Content-Type': 'application/json'}
)
resp = json.loads(urllib.request.urlopen(req).read())
print('寄出成功！ID:', resp.get('id'))
PYEOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 報告已發信給 chenyuchi09@gmail.com" >> "$LOG"
rm -f "$REPORT"
