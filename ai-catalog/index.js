/**
 * ai-catalog skill — agent-callable interface
 * Usage: const catalog = require('./ai-catalog')
 */

const fs   = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const GENERATE = path.join(__dirname, 'bin/generate.py');
const ADD_SH   = path.join(__dirname, 'bin/catalog-add.sh');
const CONFIG   = path.join(__dirname, 'config.json');

const STATUS_LABELS = {
  installed: '✅ 已安裝',
  pending:   '⏳ 待處理',
  review:    '🔍 待評估',
  blocked:   '❌ 無法使用',
};

function loadConfig() {
  try { return JSON.parse(fs.readFileSync(CONFIG, 'utf8')); }
  catch { return {}; }
}

function resolveCatalogPath() {
  const cfg = loadConfig();
  const rel = cfg.catalog_file || 'ai-tools-catalog.md';
  return path.isAbsolute(rel) ? rel : path.join(__dirname, rel);
}

function sanitize(str) {
  // Strip shell metacharacters to prevent injection
  return String(str).replace(/[`$\\;|&<>(){}!]/g, '').slice(0, 200);
}

function readCatalog() {
  const catalogPath = resolveCatalogPath();
  const text = fs.readFileSync(catalogPath, 'utf8');
  const agents = [];
  let currentAgent = null, currentSection = null;

  for (const raw of text.split('\n')) {
    const line = raw.trimEnd();
    if (/^## /.test(line) && !/^## 狀態/.test(line)) {
      if (currentAgent) agents.push(currentAgent);
      currentAgent = { title: line.slice(3).trim(), sections: [] };
      currentSection = null;
    } else if (/^### /.test(line) && currentAgent) {
      currentSection = { title: line.slice(4).trim(), tools: [] };
      currentAgent.sections.push(currentSection);
    } else if (currentSection && line.startsWith('|') && !/^\| 工具/.test(line) && !/^\|---/.test(line)) {
      const cols = line.split('|').slice(1, -1).map(c => c.trim());
      if (cols.length >= 3) {
        const name = cols[0].replace(/\*\*(.+?)\*\*/g, '$1');
        const statusRaw = cols[1];
        let statusKey = '';
        if (statusRaw.includes('✅')) statusKey = 'installed';
        else if (statusRaw.includes('⏳')) statusKey = 'pending';
        else if (statusRaw.includes('🔍')) statusKey = 'review';
        else if (statusRaw.includes('❌')) statusKey = 'blocked';
        currentSection.tools.push({
          name, statusKey, status: statusRaw,
          feature: cols[2],
          cost: cols[3] || '',
          note: cols[cols.length - 1] || '',
          agent: currentAgent.title,
          section: currentSection.title,
        });
      }
    }
  }
  if (currentAgent) agents.push(currentAgent);
  return agents;
}

module.exports = {
  /**
   * 新增工具到目錄
   * @param {string} name       - 工具名稱
   * @param {string} agentKey   - agent 關鍵字（對應 config.json agents[].label）
   * @param {string} sectionKey - 子分類關鍵字
   * @param {string} status     - installed / pending / review / blocked
   * @param {string} feature    - 功能描述
   * @param {string} [cost]     - 費用
   * @param {string} [note]     - 備註
   */
  add(name, agentKey, sectionKey, status, feature, cost = '', note = '') {
    // Use spawnSync with argument array — no shell interpolation, no injection risk
    const result = spawnSync('bash', [
      ADD_SH,
      sanitize(name),
      sanitize(agentKey),
      sanitize(sectionKey),
      sanitize(status),
      sanitize(feature),
      sanitize(cost),
      sanitize(note),
    ], { encoding: 'utf8' });

    if (result.status === 0) {
      return { ok: true, message: `已新增 ${name}` };
    }
    return { ok: false, message: result.stderr || result.stdout || 'unknown error' };
  },

  /**
   * 查詢工具
   * @param {object} opts - { agent, status, query }
   */
  list({ agent, status, query } = {}) {
    const agents = readCatalog();
    const results = [];
    for (const a of agents) {
      if (agent && !a.title.toLowerCase().includes(agent.toLowerCase())) continue;
      for (const sec of a.sections) {
        for (const t of sec.tools) {
          if (status && t.statusKey !== status) continue;
          if (query) {
            const q = query.toLowerCase();
            if (!t.name.toLowerCase().includes(q) && !t.feature.toLowerCase().includes(q)) continue;
          }
          results.push(t);
        }
      }
    }
    return results;
  },

  /** 重新生成 HTML */
  regenerate() {
    const result = spawnSync('python3', [GENERATE], { encoding: 'utf8' });
    if (result.status === 0) return { ok: true, message: result.stdout.trim() };
    return { ok: false, message: result.stderr || 'generate failed' };
  },

  /** 取得 config */
  config: loadConfig,

  /** 取得所有 agent 名稱 */
  agents() {
    return readCatalog().map(a => a.title);
  },
};
