#!/bin/bash
# gmail_auto_reply.sh — Reads new emails, calls Claude, routes reply to terminal or email
# Config: edit the variables below before first run

CLAUDE_BIN="${CLAUDE_BIN:-/opt/homebrew/bin/claude}"   # path to claude CLI
DATA_DIR="${DATA_DIR:-$HOME/.claude}"                   # where token/config files live
ACTIVE_THRESHOLD="${ACTIVE_THRESHOLD:-1200}"            # seconds before "away" mode (default 20 min)

INBOX="$DATA_DIR/gmail_inbox_new.json"
REPLIED="$DATA_DIR/gmail_replied_ids.txt"
LOG="$DATA_DIR/gmail_auto_reply.log"

LOCK="/tmp/gmail_auto_reply.lock"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

[ ! -f "$INBOX" ] && exit 0
touch "$REPLIED"

# 防止並發
if [ -f "$LOCK" ]; then
    log "另一個實例正在執行，跳過"
    exit 0
fi
trap "rm -f $LOCK" EXIT
touch "$LOCK"

ACTIVE_FLAG="/tmp/claude-code-active"
ACTIVE_THRESHOLD=1200  # 20 分鐘

# 判斷是否在電腦前（Claude Code 最近有活動）
USER_ACTIVE=false
if [ -f "$ACTIVE_FLAG" ]; then
    LAST=$(cat "$ACTIVE_FLAG")
    NOW=$(date +%s)
    DIFF=$((NOW - LAST))
    if [ "$DIFF" -lt "$ACTIVE_THRESHOLD" ]; then
        USER_ACTIVE=true
    fi
fi

log "=== auto_reply 啟動（模式：$([ "$USER_ACTIVE" = true ] && echo '終端機' || echo 'Email')）==="

python3 - "$USER_ACTIVE" << 'PYEOF'
import json, subprocess, os, base64, urllib.request, urllib.parse, sys
import email.mime.text, email.mime.multipart
from datetime import datetime

INBOX       = os.path.expanduser("~/.claude/gmail_inbox_new.json")
REPLIED     = os.path.expanduser("~/.claude/gmail_replied_ids.txt")
LOG         = os.path.expanduser("~/.claude/gmail_auto_reply.log")
TERMINAL_OUT= os.path.expanduser("~/.claude/gmail_terminal_inbox.md")
HOME        = os.path.expanduser("~")
USER_ACTIVE = sys.argv[1] == 'true'

def log(msg):
    with open(LOG, 'a') as f:
        f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")

def get_token():
    with open(f'{HOME}/.claude/gmail_token.json') as f: token = json.load(f)
    with open(f'{HOME}/.claude/gmail_client_secret.json') as f: d = json.load(f)['installed']
    data = urllib.parse.urlencode({
        'refresh_token': token['refresh_token'],
        'client_id': d['client_id'],
        'client_secret': d['client_secret'],
        'grant_type': 'refresh_token'
    }).encode()
    # NOTE: do NOT set Content-Type header — urlencoded body only
    resp = json.loads(urllib.request.urlopen(
        urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
    ).read())
    return resp['access_token']

def get_my_email(token):
    req = urllib.request.Request(
        'https://gmail.googleapis.com/gmail/v1/users/me/profile',
        headers={'Authorization': 'Bearer ' + token}
    )
    return json.loads(urllib.request.urlopen(req).read()).get('emailAddress', 'me')

def extract_email(addr):
    """Extract bare email address from 'Name <email>' format."""
    if '<' in addr and '>' in addr:
        return addr.split('<')[1].split('>')[0].strip()
    return addr.strip()

def send_reply(token, from_addr, to_addr, subject, body, thread_id=None, in_reply_to=None):
    to_email = extract_email(to_addr)
    msg = email.mime.multipart.MIMEMultipart()
    msg['To']      = to_email
    msg['From']    = from_addr
    msg['Subject'] = subject if subject.lower().startswith('re:') else f'Re: {subject}'
    if in_reply_to and in_reply_to.strip():
        msg['In-Reply-To'] = in_reply_to.strip()
        msg['References']  = in_reply_to.strip()
    msg.attach(email.mime.text.MIMEText(body, 'plain', 'utf-8'))

    payload = {'raw': base64.urlsafe_b64encode(msg.as_bytes()).decode()}
    if thread_id:
        payload['threadId'] = thread_id

    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
        data=data,
        headers={'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}
    )
    return json.loads(urllib.request.urlopen(req).read()).get('id', '?')

def ask_claude(prompt):
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False, encoding='utf-8') as tmp:
        tmp.write(prompt)
        tmp_path = tmp.name
    try:
        result = subprocess.run(
            ['bash', '-c', f'cat "{tmp_path}" | /opt/homebrew/bin/claude -p --output-format text 2>/dev/null'],
            capture_output=True, text=True, timeout=120,
            env={**os.environ, 'HOME': HOME, 'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'}
        )
        return result.stdout.strip()
    finally:
        os.unlink(tmp_path)

with open(REPLIED) as f:
    replied_ids = set(f.read().splitlines())

with open(INBOX) as f:
    mails = json.load(f)

# 取得自己的 email（只取一次）
try:
    token = get_token()
    my_email = get_my_email(token)
    log(f"發信身份：{my_email}")
except Exception as e:
    log(f"無法取得 token：{e}")
    exit(1)

replied_count = 0
for mail in mails:
    mail_id   = mail.get('id', '')
    if not mail_id or mail_id in replied_ids:
        continue

    subject   = mail.get('subject', '（無主旨）')
    sender    = mail.get('from', '')
    body      = mail.get('body', '').strip()
    thread_id = mail.get('threadId', '')
    msg_id    = mail.get('messageId', '')
    atts      = mail.get('attachments', [])

    # 不回覆自己寄的信
    if my_email in sender:
        log(f"跳過（自己寄的）：{subject[:40]}")
        with open(REPLIED, 'a') as f:
            f.write(mail_id + '\n')
        continue

    log(f"處理：{subject[:50]}（{sender}）")

    att_note = f"\n\n【附件已下載至本機】：{', '.join(os.path.basename(a) for a in atts)}" if atts else ""

    prompt = f"""你是 James 的 AI 助理 Claude，請以繁體中文回覆以下 email。

寄件人：{sender}
主旨：{subject}
內容：
{body}{att_note}

請直接寫回信正文（不加前言、不說明自己在做什麼）。語氣自然，表示已收到並說明理解或下一步。3~6 句話即可。"""

    try:
        reply_body = ask_claude(prompt)
        if not reply_body:
            log(f"Claude 無輸出，跳過")
            continue

        if USER_ACTIVE:
            # 終端機模式：寫入收件匣檔案 + macOS 通知
            ts = datetime.now().strftime('%Y-%m-%d %H:%M')
            with open(TERMINAL_OUT, 'a', encoding='utf-8') as f:
                f.write(f"\n---\n## [{ts}] {subject}\n**寄件人：** {sender}\n\n{reply_body}\n")
            subprocess.run([
                'osascript', '-e',
                f'display notification "主旨：{subject[:40]}" with title "📬 新信已分析" subtitle "cat ~/.claude/gmail_terminal_inbox.md 查看"'
            ], capture_output=True)
            log(f"✅ 終端機模式：已寫入 gmail_terminal_inbox.md：{subject[:40]}")
        else:
            # Email 模式：寄回信
            token = get_token()
            sent_id = send_reply(token, my_email, sender, subject, reply_body, thread_id, msg_id)
            log(f"✅ Email 回覆完成 sent={sent_id}：{subject[:40]}")
            import time; time.sleep(3)  # 避免速率限制

        with open(REPLIED, 'a') as f:
            f.write(mail_id + '\n')
        replied_count += 1

    except urllib.error.HTTPError as e:
        err_body = e.read().decode()
        log(f"❌ HTTP {e.code}（{subject[:30]}）：{err_body[:200]}")
    except Exception as e:
        log(f"❌ 失敗（{subject[:30]}）：{e}")

log(f"=== 完成，共回覆 {replied_count} 封 ===")
PYEOF
