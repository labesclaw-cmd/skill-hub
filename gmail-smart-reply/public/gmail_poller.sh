#!/bin/bash
# gmail_poller.sh — 定期掃描收件匣，抓文字 + 自動下載圖片/PDF 附件

POLL_INTERVAL=300
LAST_ID_FILE="$HOME/.claude/gmail_last_id.txt"
ALLOWED_SENDERS=("chenyuchi09@gmail.com")
LOG="$HOME/.claude/gmail_poller.log"
ATTACH_DIR="$HOME/.claude/gmail_attachments"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

mkdir -p "$ATTACH_DIR"
log "Gmail poller 啟動，白名單: ${ALLOWED_SENDERS[*]}"
touch "$LAST_ID_FILE"

while true; do
  RESULT=$(python3 << 'PYEOF'
import json, urllib.request, base64, os, re
from datetime import datetime

ALLOWED    = ["chenyuchi09@gmail.com"]
ATTACH_DIR = os.path.expanduser("~/.claude/gmail_attachments")
TOKEN_PATH = os.path.expanduser("~/.claude/gmail_token.json")
CLIENT_PATH= os.path.expanduser("~/.claude/gmail_client_secret.json")

# 允許下載的附件類型
ALLOWED_EXTS = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.pdf', '.txt', '.md'}

def get_token():
    with open(TOKEN_PATH) as f: token = json.load(f)
    with open(CLIENT_PATH) as f: d = json.load(f)['installed']
    data = json.dumps({
        'refresh_token': token['refresh_token'],
        'client_id': d['client_id'],
        'client_secret': d['client_secret'],
        'grant_type': 'refresh_token'
    }).encode()
    req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data,
        headers={'Content-Type': 'application/json'})
    return json.loads(urllib.request.urlopen(req).read())['access_token']

def api_get(token, url):
    req = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + token})
    return json.loads(urllib.request.urlopen(req).read())

def extract_body(payload):
    parts = payload.get('parts', [])
    if parts:
        for part in parts:
            if part.get('mimeType') == 'text/plain':
                data = part['body'].get('data', '')
                if data:
                    return base64.urlsafe_b64decode(data + '==').decode('utf-8', errors='replace')
            # 遞迴找 nested parts
            if part.get('parts'):
                result = extract_body(part)
                if result:
                    return result
    else:
        data = payload.get('body', {}).get('data', '')
        if data:
            return base64.urlsafe_b64decode(data + '==').decode('utf-8', errors='replace')
    return ''

def find_attachments(parts, results=None):
    if results is None: results = []
    for part in parts:
        filename = part.get('filename', '')
        body     = part.get('body', {})
        sub      = part.get('parts', [])
        if filename:
            results.append({
                'filename':     filename,
                'attachmentId': body.get('attachmentId'),
                'data':         body.get('data'),
                'mimeType':     part.get('mimeType', '')
            })
        if sub:
            find_attachments(sub, results)
    return results

def safe_filename(name):
    return re.sub(r'[^\w.\-]', '_', name)

def download_attachments(token, msg_id, subject, attachments):
    saved = []
    date_prefix = datetime.now().strftime('%Y-%m-%d')
    subj_slug   = safe_filename(subject[:30])
    for att in attachments:
        fname = att['filename']
        ext   = os.path.splitext(fname)[-1].lower()
        if ext not in ALLOWED_EXTS:
            continue
        try:
            if att['attachmentId']:
                resp = api_get(token,
                    f'https://gmail.googleapis.com/gmail/v1/users/me/messages/{msg_id}/attachments/{att["attachmentId"]}')
                file_data = base64.urlsafe_b64decode(resp['data'] + '==')
            elif att['data']:
                file_data = base64.urlsafe_b64decode(att['data'] + '==')
            else:
                continue

            save_name = f'{date_prefix}_{subj_slug}_{safe_filename(fname)}'
            save_path = os.path.join(ATTACH_DIR, save_name)
            with open(save_path, 'wb') as f:
                f.write(file_data)
            saved.append(save_path)
        except Exception as e:
            pass
    return saved

try:
    token    = get_token()
    inbox    = api_get(token,
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=15&labelIds=INBOX&q=is:unread')
    messages = inbox.get('messages', [])

    new_msgs = []
    for m in messages:
        msg     = api_get(token, f'https://gmail.googleapis.com/gmail/v1/users/me/messages/{m["id"]}?format=full')
        headers = {h['name']: h['value'] for h in msg['payload'].get('headers', [])}
        sender  = headers.get('From', '')
        sender_email = sender.split('<')[-1].replace('>', '').strip() if '<' in sender else sender.strip()

        if sender_email not in ALLOWED:
            continue

        subject  = headers.get('Subject', '')
        body     = extract_body(msg['payload'])
        parts    = msg['payload'].get('parts', [])
        raw_atts = find_attachments(parts)
        saved    = download_attachments(token, m['id'], subject, raw_atts) if raw_atts else []

        new_msgs.append({
            'id':          m['id'],
            'threadId':    msg.get('threadId', ''),
            'messageId':   headers.get('Message-ID', ''),
            'from':        sender,
            'subject':     subject,
            'body':        body,
            'attachments': saved
        })

    print(json.dumps(new_msgs, ensure_ascii=False))
except Exception as e:
    import sys
    print(f'[ERROR] {e}', file=sys.stderr)
    print(json.dumps([]))
PYEOF
  )

  COUNT=$(echo "$RESULT" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)

  if [[ "$COUNT" -gt 0 ]]; then
    log "發現 $COUNT 封新信（白名單）"
    echo "$RESULT" > "$HOME/.claude/gmail_inbox_new.json"
    echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$HOME/.claude/gmail_new_flag.txt"

    # 記錄有附件的信件
    ATTACH_COUNT=$(echo "$RESULT" | python3 -c "
import json,sys
msgs = json.load(sys.stdin)
total = sum(len(m.get('attachments',[])) for m in msgs)
print(total)
" 2>/dev/null || echo 0)

    [ "$ATTACH_COUNT" -gt 0 ] && log "已下載 $ATTACH_COUNT 個附件到 $ATTACH_DIR"
    log "已更新 gmail_inbox_new.json"

    # 自動回覆觸發
    bash "$HOME/.claude/gmail_auto_reply.sh" &
    log "已觸發 auto_reply"
  fi

  sleep "$POLL_INTERVAL"
done
