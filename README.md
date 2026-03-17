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
git clone https://github.com/IsGuibo/WorkTracker.git
cd WorkTracker/WorkTracker
swift build -c release
swift run WorkTracker
```

### Package as .app / 打包为应用

```bash
cd WorkTracker/WorkTracker
bash build_app.sh
```

This creates `工作追踪.app` in the `WorkTracker/WorkTracker/` directory.

打包完成后，`WorkTracker/WorkTracker/` 目录下会生成 `工作追踪.app`，可直接拖入 `/Applications`。

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

MIT © 2026 [黄贵波 (Guibo Huang)](https://github.com/IsGuibo)
