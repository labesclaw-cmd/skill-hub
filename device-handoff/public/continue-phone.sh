#!/bin/bash
# continue-phone.sh — 在電腦終端機接續手機對話

HANDOFF="$HOME/.claude/handoff.md"

if [ ! -f "$HANDOFF" ]; then
    echo "❌ 沒有找到交接檔案，手機端尚未切換。"
    exit 1
fi

AGE=$(( $(date +%s) - $(stat -f %m "$HANDOFF") ))
if [ "$AGE" -gt 7200 ]; then
    echo "⚠️ 交接檔案已超過 2 小時，可能過期。仍要繼續嗎？(y/n)"
    read -r ans
    [ "$ans" != "y" ] && exit 0
fi

echo "📱 載入手機對話摘要..."
cat "$HANDOFF"
echo ""
echo "────────────────────────────"
echo "✅ 正在接續手機對話，請稍候..."

CONTEXT=$(cat "$HANDOFF")
rm -f "$HANDOFF"

# 帶入 context 啟動 Claude Code
claude --continue -p "【從手機接續】以下是剛才在手機上的對話摘要，請直接接續：

$CONTEXT

請確認你已了解上述內容，然後繼續協助。"
