# skill-hub

James 的 AI 技能中央倉庫。供 Claude Code、Hermes Agent、OpenClaw 共用。

## Skills

| Skill | 狀態 | 說明 |
|-------|------|------|
| [claude-notify](./claude-notify/) | ✅ 完成 | Claude 阻礙通知系統，靜默時段 + 早報 |
| [daily-report](./daily-report/) | ✅ 完成 | 每日工作報告自動生成並發信 |
| [gmail-processor](./gmail-processor/) | 🚧 開發中 | Gmail 自動分析連結並回信摘要 |

## 架構說明

- **私有倉庫**（本倉庫）：三個系統共用的工具型 skill
- **公開倉庫** [skill-store](https://github.com/labesclaw-cmd/skill-store)：原創 skill 對外發佈

## 使用的 AI 系統
- Claude Code（主要開發環境）
- Hermes Agent（Windows，本地 Gemma 26B）
- OpenClaw（Mac mini，Lapis 人設）
