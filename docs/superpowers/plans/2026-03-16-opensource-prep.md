# WorkTracker 开源准备实施计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 WorkTracker macOS 应用完成 GitHub 开源所需的全部准备工作，包括新增开源文档、从 Git 历史中清理内部文件、配置根目录 .gitignore。

**Architecture:** 纯文档与 Git 操作任务，无代码逻辑变更。按"清理内部文件 → 新增根 .gitignore → 新增 LICENSE → 新增 README → 新增 CONTRIBUTING"顺序执行，每步独立提交，方便回滚。

**Tech Stack:** Git, Markdown, Swift（仅 README 中引用命令）

---

## 文件变更总览

| 操作 | 文件 | 说明 |
|------|------|------|
| 删除（git rm --cached） | `CLAUDE.md` | Claude Code 内部指令，不入公开仓库 |
| 删除（git rm --cached） | `docs/superpowers/` | Claude Code 内部设计文档 |
| 新增 | `.gitignore` | 根目录 gitignore，防止内部文件再次误提交 |
| 新增 | `LICENSE` | MIT 许可证 |
| 新增 | `README.md` | 中英双语项目说明 |
| 新增 | `CONTRIBUTING.md` | 基础贡献指南 |

所有操作均在仓库根目录 `/Users/huangguibo/IdeaProjects/frontend-test/` 执行。

---

### Task 1：从 Git 跟踪中移除内部文件

**Files:**
- Modify (untrack): `CLAUDE.md`
- Modify (untrack): `docs/superpowers/` 目录

> 这些文件已有提交历史，仅加 .gitignore 不够，必须先 `git rm --cached`。

- [ ] **Step 1：将 CLAUDE.md 从 Git 跟踪中移除**

```bash
cd /Users/huangguibo/IdeaProjects/frontend-test
git rm --cached CLAUDE.md
```

预期输出：`rm 'CLAUDE.md'`

- [ ] **Step 2：将 docs/superpowers/ 从 Git 跟踪中移除**

```bash
git rm -r --cached docs/superpowers/
```

预期输出：依次列出 `rm 'docs/superpowers/...'` 共 3 行（plans/ 和 specs/ 下的 md 文件）

- [ ] **Step 3：确认工作区状态**

```bash
git status
```

预期：`CLAUDE.md` 和 `docs/superpowers/` 下的文件出现在 "Changes to be committed" 区域，标注为 `deleted`。文件本身仍在磁盘，不会丢失。

- [ ] **Step 4：提交**

```bash
git commit -m "chore: 从 Git 跟踪中移除内部文件（CLAUDE.md、docs/superpowers/）"
```

---

### Task 2：新增根目录 .gitignore

**Files:**
- Create: `.gitignore`（仓库根目录）

> `WorkTracker/.gitignore` 已存在且完整，此处仅为根目录新增一个，防止上层内部文件再次被提交。

- [ ] **Step 1：创建根目录 .gitignore**

文件内容：

```gitignore
# macOS
.DS_Store

# Claude Code 内部文件
.claude/
CLAUDE.md
docs/superpowers/
```

- [ ] **Step 2：验证文件存在**

```bash
cat /Users/huangguibo/IdeaProjects/frontend-test/.gitignore
```

预期：输出上述 6 行内容。

- [ ] **Step 3：提交**

```bash
git add .gitignore
git commit -m "chore: 新增根目录 .gitignore，排除内部工具文件"
```

---

### Task 3：新增 LICENSE（MIT）

**Files:**
- Create: `LICENSE`（仓库根目录）

- [ ] **Step 1：创建 LICENSE 文件**

文件内容（标准 MIT 全文）：

```
MIT License

Copyright (c) 2026 黄贵波 (Guibo Huang)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2：验证内容**

```bash
head -3 /Users/huangguibo/IdeaProjects/frontend-test/LICENSE
```

预期：
```
MIT License

Copyright (c) 2026 黄贵波 (Guibo Huang)
```

- [ ] **Step 3：提交**

```bash
git add LICENSE
git commit -m "chore: 添加 MIT 许可证"
```

---

### Task 4：新增 README.md（中英双语）

**Files:**
- Create: `README.md`（仓库根目录）

- [ ] **Step 1：创建 README.md**

文件完整内容如下：

````markdown
# WorkTracker / 工作追踪

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![MIT License](https://img.shields.io/badge/license-MIT-green)

> A native macOS app for tracking project status, tasks, and daily work logs — all stored locally as plain JSON files, no account required.
>
> 一款 macOS 原生应用，用于管理项目进度、子任务和每日工作日志。数据以纯 JSON 文件存储在本地，无需账号，无需联网。

---

## Screenshots / 截图

> Coming soon. Screenshots will be added to `docs/screenshots/`.
>
> 截图待补充，将存放于 `docs/screenshots/` 目录。

---

## Features / 功能特性

**English:**
- **Project management** — track projects with status (in progress / waiting / paused / done), priority, tags, subtasks, and notes
- **Gantt-style calendar** — visualize project timelines and daily work logs on a monthly calendar
- **Daily work log** — record what you worked on each day with man-day estimates; supports time tracking per project
- **Task tracker** — manage subtasks within each project, each with independent status
- **Draft editor** — freeform Markdown notes per project
- **Local-first** — all data in `~/WorkTracker/` as plain JSON; no cloud sync, no account, works offline
- **Productivity-focused** — designed for GTD-style project management and daily log review

**中文：**
- **项目管理** — 跟踪项目状态（进行中 / 等待 / 暂停 / 完成）、优先级、标签、子任务和备注
- **甘特式日历** — 在月历视图中查看项目时间线和每日工作记录
- **工作日志** — 按天记录工作内容，支持人天估算和按项目统计工时
- **任务管理** — 在项目内管理子任务，每个子任务有独立状态
- **草稿编辑器** — 每个项目可附加自由格式的 Markdown 笔记
- **本地优先** — 数据以纯 JSON 存储在 `~/WorkTracker/`，无云同步，无需账号，离线可用
- **专注效率** — 为 GTD 风格的项目管理和日报复盘设计

---

## Requirements / 系统要求

- macOS 14.0 (Sonoma) or later / macOS 14.0（Sonoma）及以上
- Xcode or Swift toolchain (for building from source) / 编译时需要 Xcode 或 Swift 工具链

---

## Installation / 安装

### Build from Source / 从源码编译

```bash
git clone https://github.com/your-username/WorkTracker.git
cd WorkTracker/WorkTracker
swift build -c release
swift run WorkTracker
```

### Package as .app / 打包为应用

```bash
cd WorkTracker/WorkTracker
bash build_app.sh
```

This creates `工作追踪.app` in the `WorkTracker/` directory.

打包完成后，`WorkTracker/` 目录下会生成 `工作追踪.app`，可直接拖入 `/Applications`。

---

## Data Storage / 数据存储

All data is stored in `~/WorkTracker/` on your local machine (created automatically on first launch). Nothing is sent to any server.

所有数据存储在本机 `~/WorkTracker/` 目录下（首次启动自动创建），不向任何服务器发送数据。

```
~/WorkTracker/
├── projects.json      # 项目和子任务 / Projects and subtasks
├── daily-logs.json    # 每日工作记录 / Daily work logs
└── drafts/
    └── p1.md          # 每个项目的草稿 / Per-project draft notes
```

See [`WorkTracker/claude-md-template.md`](WorkTracker/claude-md-template.md) for the full data schema.

---

## Project Structure / 项目结构

```
WorkTracker/              # Swift Package root
├── Package.swift
├── WorkTracker/          # Application source
│   ├── WorkTrackerApp.swift
│   ├── ContentView.swift
│   ├── Models/           # Project, DailyLog, Enums
│   ├── Services/         # DataStore, FileWatcher
│   ├── Utilities/        # ColorPalette, DateHelpers
│   └── Views/
│       ├── Calendar/     # CalendarMonthView, GanttBarView, DayDetailView
│       ├── Detail/       # ProjectDetailView, DraftEditorView, TaskListView
│       ├── Sidebar/      # SidebarView, ProjectRowView, NewProjectSheet
│       └── Settings/     # SettingsView
└── WorkTrackerTests/     # Unit tests
```

---

## GitHub Topics / 搜索标签

If you find this project useful, it can be found by searching:
`swift` `swiftui` `macos` `project-management` `task-tracker` `gantt` `work-log` `daily-log` `time-tracking` `productivity`

---

## Contributing / 贡献

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT © 2026 [黄贵波 (Guibo Huang)](https://github.com/your-username)
````

- [ ] **Step 2：将 README 中的 `your-username` 替换为实际 GitHub 用户名**

> 注意：如果暂时不知道用户名，可以保留 `your-username` 占位，后续更新。

- [ ] **Step 3：验证文件**

```bash
head -5 /Users/huangguibo/IdeaProjects/frontend-test/README.md
```

预期输出前 5 行包含 `# WorkTracker / 工作追踪`。

- [ ] **Step 4：提交**

```bash
git add README.md
git commit -m "docs: 新增中英双语 README"
```

---

### Task 5：新增 CONTRIBUTING.md（中英双语）

**Files:**
- Create: `CONTRIBUTING.md`（仓库根目录）

- [ ] **Step 1：创建 CONTRIBUTING.md**

文件内容：

````markdown
# Contributing to WorkTracker / 贡献指南

Thank you for your interest in contributing!
感谢你对 WorkTracker 的关注，欢迎贡献！

---

## Reporting Bugs / 报告问题

Please open a [GitHub Issue](../../issues) and include:
请在 [GitHub Issues](../../issues) 中提交，并附上：

- macOS version / macOS 版本
- Steps to reproduce / 复现步骤
- Expected vs actual behavior / 预期与实际行为

---

## Submitting a Pull Request / 提交 PR

1. Fork this repository / Fork 本仓库
2. Create a feature branch / 创建功能分支
   ```bash
   git checkout -b feat/your-feature-name
   ```
3. Make your changes / 进行修改
4. Run tests and make sure they pass / 运行测试，确保通过
   ```bash
   cd WorkTracker
   swift test
   ```
5. Commit with a clear message / 提交清晰的说明
   ```bash
   git commit -m "feat: add your feature"
   ```
6. Open a Pull Request against `main` / 向 `main` 分支发起 PR

---

## Building the Project / 编译运行

See [README.md](README.md#installation--安装) for build instructions.
编译方法见 [README.md](README.md#installation--安装)。

---

## Code Style / 代码风格

- Follow SwiftUI conventions and Apple's Human Interface Guidelines
- No additional linter is configured; keep code clean and readable
- 遵循 SwiftUI 惯例和 Apple HIG
- 无额外 lint 工具，保持代码整洁可读
````

- [ ] **Step 2：验证文件**

```bash
head -3 /Users/huangguibo/IdeaProjects/frontend-test/CONTRIBUTING.md
```

预期：`# Contributing to WorkTracker / 贡献指南`

- [ ] **Step 3：提交**

```bash
git add CONTRIBUTING.md
git commit -m "docs: 新增中英双语贡献指南"
```

---

### Task 6：最终验证

- [ ] **Step 1：确认内部文件不在 Git 跟踪中**

```bash
git -C /Users/huangguibo/IdeaProjects/frontend-test ls-files CLAUDE.md docs/superpowers/
```

预期：**无输出**（表示这两项已不在跟踪中）

- [ ] **Step 2：确认四个开源文件均已提交**

```bash
git -C /Users/huangguibo/IdeaProjects/frontend-test ls-files README.md LICENSE CONTRIBUTING.md .gitignore
```

预期输出：
```
.gitignore
CONTRIBUTING.md
LICENSE
README.md
```

- [ ] **Step 3：确认工作区干净**

```bash
git -C /Users/huangguibo/IdeaProjects/frontend-test status
```

预期：`nothing to commit, working tree clean`

- [ ] **Step 4：查看提交历史，确认步骤均已记录**

```bash
git -C /Users/huangguibo/IdeaProjects/frontend-test log --oneline -5
```

预期最近 5 条提交依次为：
```
... docs: 新增中英双语贡献指南
... docs: 新增中英双语 README
... chore: 添加 MIT 许可证
... chore: 新增根目录 .gitignore，排除内部工具文件
... chore: 从 Git 跟踪中移除内部文件（CLAUDE.md、docs/superpowers/）
```

---

## 实施后手动操作提示

以下两项需要在 GitHub 网页端手动完成，无法通过代码实现：

1. **添加仓库 Topics**（提升搜索发现性）
   - 进入仓库主页 → 右上角 ⚙️（About 旁）→ Topics
   - 添加：`swift` `swiftui` `macos` `project-management` `task-tracker` `productivity` `gantt` `work-log` `daily-log` `time-tracking`

2. **补充截图**（可选，后续完成）
   - 运行应用，截图后保存到 `docs/screenshots/`
   - 更新 `README.md` 中的 Screenshots 节，添加图片链接
