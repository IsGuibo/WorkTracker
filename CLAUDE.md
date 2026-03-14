# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 用户偏好

- 母语中文，所有回答和文档使用中文

# 项目概述

WorkTracker 是一个 macOS 原生应用（SwiftUI），用于跟踪项目状态和每日工作记录。项目代码在 `WorkTracker/` 子目录下，使用 Swift Package Manager 管理。

# 常用命令

所有命令在 `WorkTracker/` 目录下执行：

```bash
# 构建
swift build

# 运行
swift run WorkTracker

# 运行全部测试
swift test

# 运行单个测试类
swift test --filter ModelTests
swift test --filter DataStoreTests
swift test --filter CalendarHelperTests

# 清理构建产物
rm -rf .build/
```

无 lint 工具配置，SwiftUI 不需要额外的格式化工具。

# 架构概述

## 数据流

```
~/WorkTracker/（文件系统）
    ↕ FileWatcher（FSEvents API，防抖 0.3 秒）
DataStore（@MainActor ObservableObject，单一数据源）
    ↕ @EnvironmentObject
SwiftUI Views
```

`DataStore` 是核心服务，负责读写 `~/WorkTracker/` 下的三类文件：
- `projects.json`：所有项目和子任务
- `daily-logs.json`：每日工作记录
- `drafts/<项目id>.md`：每个项目的草稿（Markdown 纯文本）

`FileWatcher` 监听外部文件变更并触发 DataStore 重新加载；`ignoreNextReload` 标志防止应用自身写入触发重加载。

## UI 结构

`NavigationSplitView` 双面板布局：
- **左侧 SidebarView**：项目列表（按状态/优先级筛选）+ 日历入口
- **右侧详情区**：
  - `CalendarMonthView`：甘特式日历，显示项目时间线和日志
  - `ProjectDetailView`：项目编辑（标签、优先级、状态、子任务、草稿）

## 数据模型关键约束

- 项目 id 格式：`p<数字>`（全局递增，取现有最大数字 +1）
- 任务 id 格式：`t<数字>`（跨项目全局唯一）
- 日期格式统一：`YYYY-MM-DD`
- 修改 `status` 时必须同时向 `statusHistory` 追加一条记录
- `completedDate` 在状态改为 `done` 时自动设置

## 颜色系统

`ColorPalette.swift` 提供两套颜色：
- **项目色**：10 色池，用 djb2 哈希确保同一项目 id 始终映射同一颜色
- **状态色** / **优先级色**：固定语义映射（进行中→蓝、等待→橙、完成→绿、紧急→红）

## 数据格式规范（详见 `WorkTracker/claude-md-template.md`）

JSON 文件使用 2 空格缩进；`drafts/` 目录不存在时先创建再写入；解析失败时保留上次成功加载的数据并在 UI 顶部显示错误。
