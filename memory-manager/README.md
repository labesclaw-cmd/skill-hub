# memory-manager

AI 記憶管理系統。採用 RAG 概念，只把輕量索引載入上下文，需要時才抓取詳細記憶，避免 token 浪費。

## 架構
```
~/.claude/memory/
├── INDEX.md        ← 每次 session 載入（輕量，< 30 行）
├── active/         ← 進行中的任務記憶
└── archive/        ← 已完成任務的壓縮摘要
```

## 三個指令

| 指令 | 用途 |
|------|------|
| `mem-init.sh` | 初始化，遷移現有記憶 |
| `mem-archive.sh <檔案>` | 壓縮封存已完成任務 |
| `mem-recall.sh <關鍵字>` | 搜尋並讀取 archive |

## 使用流程

**初次安裝：**
```bash
bash ~/skill-hub/memory-manager/bin/mem-init.sh
```

**任務完成後封存：**
```bash
bash ~/skill-hub/memory-manager/bin/mem-archive.sh project_lineage381.md
```

**需要調閱舊記憶：**
```bash
bash ~/skill-hub/memory-manager/bin/mem-recall.sh hermes
```

## 設計原則
- INDEX.md 永遠保持 < 30 行
- active/ 只放進行中的任務
- archive/ 只存摘要，原始內容壓縮保留
- 用完即棄，不放回上下文

## 版本
- v1.0.0 — 2026-04-21 初始版本
