const { Client, GatewayIntentBits, Partials } = require('discord.js');
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// ── 設定 ──────────────────────────────────────────────────────────
const configPath = path.join(process.env.HOME, '.claude/discord_config.sh');
const configContent = fs.readFileSync(configPath, 'utf8');
const tokenMatch = configContent.match(/DISCORD_BOT_TOKEN="([^"]+)"/);
if (!tokenMatch) { console.error('找不到 DISCORD_BOT_TOKEN'); process.exit(1); }
const TOKEN = tokenMatch[1];
const OWNER_ID   = process.env.DISCORD_OWNER_ID || '';
const HANDOFF    = path.join(process.env.HOME, '.claude/handoff.md');
const LOG_PATH   = path.join(process.env.HOME, '.claude/discord_bridge.log');
const HANDOFF_TTL = 7200; // 2小時過期

// ── 每個頻道的狀態 ────────────────────────────────────────────────
const sessions  = {};   // { channelId: { started: bool, buffer: [{role,content}] } }

function getSession(channelId) {
    if (!sessions[channelId]) {
        sessions[channelId] = { started: false, buffer: [] };
    }
    return sessions[channelId];
}

function log(msg) {
    const line = `[${new Date().toISOString()}] ${msg}\n`;
    fs.appendFileSync(LOG_PATH, line);
    console.log(msg);
}

// ── Handoff 工具 ───────────────────────────────────────────────────
function readHandoff() {
    if (!fs.existsSync(HANDOFF)) return null;
    const stat = fs.statSync(HANDOFF);
    const age  = (Date.now() - stat.mtimeMs) / 1000;
    if (age > HANDOFF_TTL) { fs.unlinkSync(HANDOFF); return null; }
    const content = fs.readFileSync(HANDOFF, 'utf8').trim();
    fs.unlinkSync(HANDOFF); // 消費後立即刪除
    return content;
}

function writeHandoff(from, summary) {
    const ts = new Date().toLocaleString('zh-TW', { timeZone: 'Asia/Taipei' });
    const content = `# 交接摘要（${from} → ${from === '手機' ? '電腦' : '手機'}）— ${ts}\n\n${summary}`;
    fs.writeFileSync(HANDOFF, content, 'utf8');
    log(`已寫入 handoff.md（${from} 切換）`);
}

// ── 對話 buffer 摘要（最多保留最近 10 則）──────────────────────────
function bufferSummary(buffer) {
    const recent = buffer.slice(-10);
    return recent.map(m => `[${m.role === 'user' ? 'BOSS' : 'Claude'}] ${m.content.substring(0, 200)}`).join('\n');
}

// ── 呼叫 Claude ────────────────────────────────────────────────────
function askClaude(message, channelId) {
    const session = getSession(channelId);
    const continueFlag = session.started ? '--continue' : '';
    session.started = true;

    const tmpInput = `/tmp/discord_input_${channelId}.txt`;
    fs.writeFileSync(tmpInput, message, 'utf8');

    try {
        const result = spawnSync('bash', ['-c',
            `cat "${tmpInput}" | claude -p ${continueFlag} --output-format text 2>/dev/null`
        ], {
            timeout: 120000,
            maxBuffer: 1024 * 1024 * 10,
            env: { ...process.env, HOME: process.env.HOME }
        });

        const output = (result.stdout || '').toString().trim();
        return output || '（沒有回應，請再試一次）';
    } catch (e) {
        log(`Claude 呼叫失敗：${e.message}`);
        return `執行失敗：${e.message}`;
    }
}

// ── Discord Client ────────────────────────────────────────────────
const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.DirectMessages,
        GatewayIntentBits.DirectMessageReactions,
        GatewayIntentBits.DirectMessageTyping,
    ],
    partials: [Partials.Channel, Partials.Message, Partials.User, Partials.GuildMember, Partials.Reaction]
});

client.once('clientReady', () => {
    const guilds = client.guilds.cache.map(g => g.name).join(', ');
    log(`✅ ClaudeBridge 上線：${client.user.tag}｜伺服器：${guilds}`);
});

client.on('messageCreate', async (msg) => {
    if (msg.author.bot) return;
    if (msg.partial) { try { await msg.fetch(); } catch(e) { return; } }
    if (OWNER_ID && msg.author.id !== OWNER_ID) {
        await msg.reply('⛔ 未授權');
        return;
    }

    const content = msg.content.trim();
    if (!content) return;

    const session = getSession(msg.channelId);

    // ── 指令處理 ──────────────────────────────────────────────────

    // !reset — 重置 session
    if (content === '!reset') {
        sessions[msg.channelId] = { started: false, buffer: [] };
        await msg.reply('✅ 對話已重置');
        return;
    }

    // !status
    if (content === '!status') {
        const handoffExists = fs.existsSync(HANDOFF);
        await msg.reply(`Session：${session.started ? '✅ 持續中' : '🆕 新的'}\n待交接：${handoffExists ? '📦 有' : '無'}`);
        return;
    }

    // 切換回電腦 — 把 buffer 摘要寫入 handoff.md
    if (content.includes('切換回電腦') || content.includes('切換到電腦') ||
        content.includes('切換到dc') || content.includes('切換到DC') ||
        content.includes('切換到discord') || content.includes('切換到Discord') ||
        content.includes('我在咖啡廳')) {
        const summary = session.buffer.length > 0
            ? `## 剛才討論的內容\n${bufferSummary(session.buffer)}`
            : '## 剛才討論的內容\n（無紀錄）';
        writeHandoff('手機', summary);
        await msg.reply('📦 已封存對話摘要，回到電腦輸入 `bash ~/continue-phone.sh` 即可接續。');
        return;
    }

    // ── 一般訊息處理 ──────────────────────────────────────────────

    // 檢查是否有電腦端的 handoff（切換到手機時生成的）
    let prompt = content;
    if (!session.started) {
        const handoff = readHandoff();
        if (handoff) {
            prompt = `【從電腦接續】以下是電腦端的對話摘要：\n\n${handoff}\n\n---\n\nBOSS 說：${content}`;
            log('注入電腦端 handoff 摘要');
        }
    }

    // 加入 buffer（最多保留 20 則）
    session.buffer.push({ role: 'user', content });
    if (session.buffer.length > 20) session.buffer.shift();

    await msg.channel.sendTyping();
    log(`收到：${content.substring(0, 80)}`);

    const reply = askClaude(prompt, msg.channelId);
    session.buffer.push({ role: 'assistant', content: reply });

    log(`回覆長度：${reply.length}`);

    // 超過 2000 字切割發送
    if (reply.length <= 1900) {
        await msg.reply(reply);
    } else {
        const chunks = reply.match(/.{1,1900}/gs) || [];
        for (const chunk of chunks) {
            await msg.channel.send(chunk);
        }
    }
});

client.login(TOKEN);
