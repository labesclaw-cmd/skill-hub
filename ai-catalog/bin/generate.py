#!/usr/bin/env python3
"""
ai-catalog generator
把 catalog.md 轉換成桌面 HTML 快速查閱頁面
"""

import re, json, os, sys
from datetime import datetime

CATALOG_FILE = os.path.expanduser("~/skill-hub/ai-tools-catalog.md")
OUTPUT_FILE  = os.path.expanduser("~/Desktop/AI工具目錄.html")

STATUS_MAP = {
    "✅": ("installed", "✅ 已安裝/可用"),
    "⏳": ("pending",   "⏳ 待處理"),
    "🔍": ("review",    "🔍 待評估"),
    "❌": ("blocked",   "❌ 無法使用"),
}

def parse_catalog(path):
    sections = []
    current = None
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()

    for line in lines:
        line = line.rstrip()
        # 二級標題 = 分類
        if line.startswith("## "):
            if current:
                sections.append(current)
            current = {"title": line[3:].strip(), "tools": []}
        # 表格資料行
        elif current and line.startswith("|") and not line.startswith("| 工具") and not line.startswith("|---"):
            cols = [c.strip() for c in line.split("|")[1:-1]]
            if len(cols) >= 3:
                name    = re.sub(r"\*\*(.+?)\*\*", r"\1", cols[0])
                status  = cols[1]
                feature = cols[2]
                cost    = cols[3] if len(cols) > 3 else ""
                note    = cols[-1] if len(cols) > 4 else ""
                status_key = next((k for k in STATUS_MAP if k in status), "")
                current["tools"].append({
                    "name": name, "status": status,
                    "status_key": STATUS_MAP.get(status_key, ("", ""))[0],
                    "status_label": STATUS_MAP.get(status_key, ("", status))[1],
                    "feature": feature, "cost": cost, "note": note
                })

    if current:
        sections.append(current)
    return sections

def generate_html(sections):
    updated = datetime.now().strftime("%Y-%m-%d %H:%M")

    cards_html = ""
    for sec in sections:
        if not sec["tools"]:
            continue
        tools_html = ""
        for t in sec["tools"]:
            tools_html += f"""
            <div class="tool-card {t['status_key']}">
                <div class="tool-header">
                    <span class="tool-name">{t['name']}</span>
                    <span class="badge {t['status_key']}">{t['status_label']}</span>
                </div>
                <div class="tool-feature">{t['feature']}</div>
                {"<div class='tool-cost'>💰 " + t['cost'] + "</div>" if t['cost'] else ""}
                {"<div class='tool-note'>📌 " + t['note'] + "</div>" if t['note'] else ""}
            </div>"""

        cards_html += f"""
        <div class="section">
            <h2>{sec['title']}</h2>
            <div class="tools-grid">{tools_html}</div>
        </div>"""

    return f"""<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI 工具目錄</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
         background: #0f1117; color: #e2e8f0; padding: 24px; }}
  h1 {{ font-size: 28px; color: #a78bfa; margin-bottom: 4px; }}
  .updated {{ font-size: 12px; color: #64748b; margin-bottom: 32px; }}
  .section {{ margin-bottom: 36px; }}
  .section h2 {{ font-size: 18px; color: #94a3b8; border-bottom: 1px solid #1e293b;
                 padding-bottom: 8px; margin-bottom: 16px; }}
  .tools-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 12px; }}
  .tool-card {{ background: #1e293b; border-radius: 10px; padding: 14px;
                border-left: 4px solid #334155; transition: transform .15s; }}
  .tool-card:hover {{ transform: translateY(-2px); }}
  .tool-card.installed {{ border-left-color: #22c55e; }}
  .tool-card.pending   {{ border-left-color: #f59e0b; }}
  .tool-card.review    {{ border-left-color: #3b82f6; }}
  .tool-card.blocked   {{ border-left-color: #ef4444; }}
  .tool-header {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }}
  .tool-name {{ font-weight: 600; font-size: 15px; color: #f1f5f9; }}
  .badge {{ font-size: 11px; padding: 2px 8px; border-radius: 99px; white-space: nowrap; }}
  .badge.installed {{ background: #14532d; color: #86efac; }}
  .badge.pending   {{ background: #451a03; color: #fcd34d; }}
  .badge.review    {{ background: #1e3a5f; color: #93c5fd; }}
  .badge.blocked   {{ background: #450a0a; color: #fca5a5; }}
  .tool-feature {{ font-size: 13px; color: #94a3b8; margin-bottom: 6px; }}
  .tool-cost, .tool-note {{ font-size: 12px; color: #64748b; margin-top: 4px; }}

  /* 搜尋 */
  .search-bar {{ width: 100%; max-width: 400px; padding: 10px 16px;
                 background: #1e293b; border: 1px solid #334155; border-radius: 8px;
                 color: #e2e8f0; font-size: 14px; margin-bottom: 28px; outline: none; }}
  .search-bar:focus {{ border-color: #a78bfa; }}

  /* 篩選 */
  .filters {{ display: flex; gap: 8px; margin-bottom: 24px; flex-wrap: wrap; }}
  .filter-btn {{ padding: 6px 14px; border-radius: 99px; font-size: 13px; cursor: pointer;
                 background: #1e293b; border: 1px solid #334155; color: #94a3b8; }}
  .filter-btn.active {{ background: #a78bfa; color: #fff; border-color: #a78bfa; }}
</style>
</head>
<body>
<h1>🗂️ AI 工具目錄</h1>
<div class="updated">最後更新：{updated}</div>

<input class="search-bar" type="text" placeholder="🔍 搜尋工具名稱或功能..." oninput="filterTools(this.value)">

<div class="filters">
  <button class="filter-btn active" onclick="filterStatus('all', this)">全部</button>
  <button class="filter-btn" onclick="filterStatus('installed', this)">✅ 已安裝</button>
  <button class="filter-btn" onclick="filterStatus('pending', this)">⏳ 待處理</button>
  <button class="filter-btn" onclick="filterStatus('review', this)">🔍 待評估</button>
  <button class="filter-btn" onclick="filterStatus('blocked', this)">❌ 無法使用</button>
</div>

<div id="catalog">{cards_html}</div>

<script>
function filterTools(q) {{
  q = q.toLowerCase();
  document.querySelectorAll('.tool-card').forEach(c => {{
    c.style.display = c.textContent.toLowerCase().includes(q) ? '' : 'none';
  }});
}}
function filterStatus(status, btn) {{
  document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  document.querySelectorAll('.tool-card').forEach(c => {{
    c.style.display = (status === 'all' || c.classList.contains(status)) ? '' : 'none';
  }});
}}
</script>
</body>
</html>"""

if __name__ == "__main__":
    if not os.path.exists(CATALOG_FILE):
        print(f"找不到 catalog 檔案：{CATALOG_FILE}")
        sys.exit(1)
    sections = parse_catalog(CATALOG_FILE)
    html = generate_html(sections)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"✅ 已生成：{OUTPUT_FILE}")
