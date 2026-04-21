#!/bin/bash
# claude-notify — Claude 阻礙通知系統
# 08:00-22:00 即時通知，22:00-08:00 靜默累積，08:00 發早報
#
# 設定：把收件人 email 存到 ~/.claude/notify_config.sh
#   echo 'NOTIFY_EMAIL="your@email.com"' > ~/.claude/notify_config.sh

QUEUE="$HOME/.claude/notify_queue.json"
LOG="$HOME/.claude/notify.log"
HOUR=$(date +%H)

# 載入個人設定
[ -f "$HOME/.claude/notify_config.sh" ] && source "$HOME/.claude/notify_config.sh"
NOTIFY_EMAIL="${NOTIFY_EMAIL:-}"

if [ -z "$NOTIFY_EMAIL" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: NOTIFY_EMAIL 未設定，請建立 ~/.claude/notify_config.sh" >> "$LOG"
    exit 1
fi

TOKEN_JSON="$HOME/.claude/gmail_token.json"
CLIENT_JSON="$HOME/.claude/gmail_client_secret.json"

notify_send() {
    local subject="$1"
    local body="$2"
    python3 - "$TOKEN_JSON" "$CLIENT_JSON" "$NOTIFY_EMAIL" "$subject" "$body" << 'PYEOF'
import json, urllib.request, urllib.parse, base64, email.mime.text, sys

token_path, client_path, to_addr, subject, body = sys.argv[1:]

def get_token():
    with open(token_path) as f:
        token = json.load(f)
    with open(client_path) as f:
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

msg = email.mime.text.MIMEText(body, 'plain', 'utf-8')
msg['To']      = to_addr
msg['Subject'] = subject
msg['From']    = 'me'
raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
req = urllib.request.Request(
    'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
    data=json.dumps({'raw': raw}).encode(),
    headers={'Authorization': 'Bearer ' + get_token(), 'Content-Type': 'application/json'}
)
json.loads(urllib.request.urlopen(req).read())
print('sent')
PYEOF
}

queue_add() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    python3 -c "
import json, os
q = '$QUEUE'
items = []
if os.path.exists(q):
    with open(q) as f:
        try: items = json.load(f)
        except: items = []
items.append({'time': '$timestamp', 'message': '$message'})
with open(q, 'w') as f:
    json.dump(items, f, ensure_ascii=False, indent=2)
"
}

queue_flush() {
    python3 -c "
import json, os
q = '$QUEUE'
if not os.path.exists(q): exit()
with open(q) as f:
    try: items = json.load(f)
    except: items = []
if not items: exit()
lines = '\n'.join([f\"- [{i['time']}] {i['message']}\" for i in items])
print(lines)
open(q, 'w').write('[]')
" 2>/dev/null
}

# 主邏輯
MODE="$1"
MESSAGE="$2"

case "$MODE" in
    alert)
        ALERT_FLAG="$HOME/.claude/notify_alert_$(echo "$MESSAGE" | md5).flag"

        if [ "$HOUR" -ge 8 ] && [ "$HOUR" -lt 22 ]; then
            if [ ! -f "$ALERT_FLAG" ]; then
                notify_send "⚠️ Claude 需要你確認" "以下任務需要你的回應：

$MESSAGE

請到 Claude Code 繼續操作。
（若 10 分鐘內未回應，將再提醒一次）"
                echo "$(date +%s)" > "$ALERT_FLAG"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] 第一次通知已發送：$MESSAGE" >> "$LOG"
            else
                FIRST_TIME=$(cat "$ALERT_FLAG")
                NOW=$(date +%s)
                DIFF=$((NOW - FIRST_TIME))
                if [ "$DIFF" -ge 600 ] && [ "$DIFF" -lt 660 ]; then
                    notify_send "🔔 Claude 再次提醒：需要你確認" "此任務仍在等待你的回應：

$MESSAGE

請到 Claude Code 繼續操作。（這是最後一次提醒）"
                    echo "sent_twice" >> "$ALERT_FLAG"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 第二次提醒已發送：$MESSAGE" >> "$LOG"
                fi
            fi
        else
            queue_add "$MESSAGE"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 靜默時段，已加入佇列：$MESSAGE" >> "$LOG"
        fi
        ;;

    clear)
        ALERT_FLAG="$HOME/.claude/notify_alert_$(echo "$MESSAGE" | md5).flag"
        rm -f "$ALERT_FLAG"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 已清除通知 flag：$MESSAGE" >> "$LOG"
        ;;

    morning)
        QUEUED=$(queue_flush)
        if [ -n "$QUEUED" ]; then
            notify_send "☀️ Claude 昨夜卡住的任務（早報）" "以下是昨晚 22:00 後累積的待確認任務：

$QUEUED

請到 Claude Code 逐一確認。"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 早報已發送" >> "$LOG"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 早報：無待確認任務" >> "$LOG"
        fi
        ;;
esac
