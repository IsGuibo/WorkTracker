# WorkTracker 开源准备设计文档

**日期**：2026-03-16
**状态**：已批准

---

## 背景

WorkTracker 是一个功能完整的 macOS 原生 SwiftUI 应用，用于跟踪项目状态和每日工作记录。项目代码质量良好，有测试覆盖，现准备在 GitHub 上开源。

---

## 目标

- 让仓库在 GitHub 上看起来专业、易于发现
- 中英双语文档，面向中文和国际用户
- MIT 许可证，保持最高自由度
- 通过关键词策略提升搜索发现性

---

## 范围（方案 A：最小可行开源）

### 新增文件

| 文件 | 位置 | 说明 |
|------|------|------|
| `README.md` | 仓库根目录 | 中英双语，含功能介绍、安装说明、数据目录说明 |
| `LICENSE` | 仓库根目录 | MIT 许可证，版权人：黄贵波 (Guibo Huang)，2026 |
| `CONTRIBUTING.md` | 仓库根目录 | 基础贡献指南，中英双语 |
| `.gitignore` | 仓库根目录 | 排除 `.DS_Store`、`.claude/`、`docs/superpowers/` |

### 删除内容

- `docs/superpowers/` 目录：Claude Code 内部设计文档，不应出现在公开仓库

### 保留内容

- `WorkTracker/CLAUDE.md`（实为根目录 CLAUDE.md）：项目说明，无敏感信息，对使用 Claude Code 的贡献者有用
- `WorkTracker/claude-md-template.md`：数据格式文档，对用户有参考价值
- `WorkTracker/.gitignore`：已完整，无需修改

---

## README 结构

```
# WorkTracker / 工作追踪

[badges: macOS 14+ | Swift 5.9 | MIT License]

> 一句话简介（中英各一行）

## Screenshots / 截图

## Features / 功能特性
覆盖关键词：task tracker, work log, time tracking, GTD,
甘特图, 工作日志, 任务管理, project management, productivity

## Requirements / 系统要求

## Installation / 安装
- swift build / swift run
- build_app.sh 打包脚本

## Data Storage / 数据存储
~/WorkTracker/ 目录，自动创建，不在仓库内

## Project Structure / 项目结构

## GitHub Topics 设置指引

## License
MIT © 2026 黄贵波 (Guibo Huang)
```

---

## 关键词策略

### README 自然覆盖词汇
- 中文：工作追踪、项目管理、甘特图、工作日志、任务管理、日报、人天
- 英文：project management, task tracker, gantt chart, work log, daily log, time tracking, productivity, GTD

### 推荐 GitHub Topics（需仓库设置中手动添加）
`swift` `swiftui` `macos` `project-management` `task-tracker` `productivity` `gantt` `work-log` `daily-log` `time-tracking`

---

## CONTRIBUTING.md 结构

- 欢迎贡献说明
- 报告 Bug（GitHub Issue）
- 提交 PR 流程：Fork → 新分支 → 提交 → PR
- 编译运行方法（指向 README）
- 代码风格说明：遵循 SwiftUI 惯例，无额外 lint 要求

---

## 不在本次范围内

- GitHub Actions CI（项目简单，用户可本地 `swift build`）
- Issue / PR 模板
- CHANGELOG
- CODE_OF_CONDUCT
- GitHub Pages
