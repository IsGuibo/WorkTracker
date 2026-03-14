# WorkTracker — macOS 原生工作进度管理 App

## 概述

一个 SwiftUI macOS 原生应用，用于展示和管理个人工作进度。数据存储为本地 JSON/Markdown 文件，通过 Claude Code 直接操作文件来录入和更新数据，App 监听文件变化实时刷新 UI。

## 核心设计理念

- App 主要负责展示，数据录入交给 Claude Code
- 数据即文件，文件即数据，所有状态都在本地文件系统中
- App 内也提供基本编辑能力（改状态、写草稿）

## 数据层

### 数据目录

用户首次启动时选择数据目录，默认 `~/WorkTracker/`。App 记住上次选择。

### 目录结构

```
~/WorkTracker/
├── projects.json
├── daily-logs.json
└── drafts/
    ├── p1.md
    ├── p2.md
    └── ...
```

### projects.json

存储所有项目及其子任务。

```json
{
  "projects": [
    {
      "id": "p1",
      "name": "DP项目",
      "status": "in_progress",
      "priority": "high",
      "tags": ["定开"],
      "currentStatus": "等客户确认接口方案",
      "startDate": "2026-03-10",
      "dueDate": "2026-03-28",
      "pausedAt": null,
      "description": "DP定开项目",
      "tasks": [
        {
          "id": "t1",
          "name": "接口方案设计",
          "status": "done",
          "currentStatus": "已完成"
        },
        {
          "id": "t2",
          "name": "客户确认",
          "status": "waiting",
          "currentStatus": "等客户回复邮件"
        }
      ]
    }
  ]
}
```

字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 唯一标识，格式 `p<数字>` |
| name | string | 项目名称 |
| status | enum | `not_started` / `in_progress` / `waiting` / `done` / `paused` |
| priority | enum | `low` / `medium` / `high` / `urgent` |
| tags | string[] | 自由标签 |
| currentStatus | string | 当前进展的文字描述，如"等客户确认" |
| startDate | string | 开始日期，ISO 格式 |
| dueDate | string | 截止日期，ISO 格式，可选 |
| pausedAt | string | 暂停日期，ISO 格式，status 为 paused 时记录，恢复时清除，可选 |
| description | string | 项目简述 |
| tasks | Task[] | 子任务列表 |

子任务 Task 字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 唯一标识，格式 `t<数字>` |
| name | string | 任务名称 |
| status | enum | 同项目 status |
| currentStatus | string | 当前进展文字描述 |

### daily-logs.json

每日工作记录，日历视图的数据源。

```json
{
  "logs": [
    {
      "date": "2026-03-14",
      "entries": [
        {
          "projectId": "p1",
          "taskId": "t2",
          "summary": "完成了3个接口的改造",
          "hoursSpent": 4
        }
      ]
    }
  ]
}
```

字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| date | string | 日期，ISO 格式 |
| entries | Entry[] | 当天的工作条目 |
| entries[].projectId | string | 关联项目 id |
| entries[].taskId | string | 关联子任务 id，可选 |
| entries[].summary | string | 工作内容摘要 |
| entries[].hoursSpent | number | 花费小时数，可选 |

### drafts/<项目id>.md

每个项目的自由草稿，Markdown 格式。文件名为项目 id（如 `p1.md`）。文件不存在即无草稿，无需额外字段标记。

内容完全自由，例如：

```markdown
# DP项目 - 草稿

## 3/14 想法
- 接口方案要注意兼容性
- 跟客户确认一下字段命名

## 待确认
- [ ] 数据迁移方案
- [ ] 上线时间节点
```

## UI 设计

### 窗口布局

```
┌──────────────────────────────────────────────────┐
│  工具栏：数据源路径 | 视图切换（项目/日历）| 筛选    │
├────────────┬─────────────────────────────────────┤
│            │                                     │
│  项目列表   │   主内容区                           │
│            │                                     │
│  ● DP项目   │   切换显示：                         │
│   等客户确认 │   - 项目详情（含子任务 + 草稿tab）     │
│  ● 用户重构  │   - 日历月视图                       │
│   在改接口   │   - 日详情（点击某天后展开）           │
│            │                                     │
│  筛选：状态  │                                     │
│  标签/优先级 │                                     │
└────────────┴─────────────────────────────────────┘
```

### 页面说明

#### 1. 项目列表（左侧边栏）

- 显示所有项目，每项包含：项目名称、currentStatus 文字、状态标签（彩色）、优先级标记
- 支持按状态、标签、优先级筛选
- 点击选中项目，右侧展示详情

#### 2. 项目详情页（右侧主区域）

上方：项目基本信息卡片（名称、状态、优先级、标签、起止日期、currentStatus）

下方分两个 tab：
- 「子任务」tab：子任务列表，每项显示名称、状态标签、currentStatus。可在 App 内点击切换状态。
- 「草稿」tab：渲染对应 `drafts/<id>.md` 的 Markdown 内容。提供编辑模式，保存时回写文件。

#### 3. 日历月视图

- 标准月历网格布局，支持切换月份
- 日期网格下方叠加项目时间线条（甘特图风格）：
  - 每个有 `startDate` 的项目显示为一条横向色条，从 startDate 横跨到 dueDate（无 dueDate 则延伸到当前日期）
  - 色条颜色按项目自动分配（可基于项目 id hash 或按创建顺序轮换预设色板）
  - 多个项目时间重叠时，色条垂直堆叠
  - 色条上显示项目名称（空间不够时截断）
  - 点击色条跳转到对应项目详情
- 点击日期数字进入日详情视图
- 已完成（done）的项目色条降低透明度区分
- 暂停（paused）的项目时间线特殊处理：
  - 色条从 startDate 画到 pausedAt，末端加暂停标记
  - 恢复时（status 改回 in_progress，清除 pausedAt），色条继续正常延伸

#### 4. 日详情

- 点击月视图中某一天，右侧主区域切换为日详情视图，顶部显示返回按钮回到月视图
- 列出当天所有工作记录：关联项目名、子任务名、工作摘要、花费时间
- 可从日详情跳转到对应项目详情

## 技术实现

### 技术栈

- Swift + SwiftUI，macOS 原生应用
- 最低支持 macOS 14 (Sonoma)
- Xcode 项目，Swift Package Manager 管理依赖

### 文件监听

使用 `FSEvents` API（通过 `DispatchSource` 或 CoreServices FSEvents C API）递归监听数据目录：

- 递归监听整个数据目录，包括 `drafts/` 子目录内文件的内容变化
- 文件变化时做防抖处理（300ms），避免频繁刷新
- 重新解析对应文件，更新 `@Published` 属性，SwiftUI 自动刷新 UI

### 错误处理

- JSON 解析失败时（如 Claude Code 写入了不完整的内容），保留上一次的有效数据，UI 顶部显示错误提示条
- 解析失败后 1 秒自动重试一次，覆盖写入中途被读取的情况

### 首次启动 / 空目录

- 用户选择数据目录后，如果 `projects.json` 不存在，自动创建 `{"projects": []}`
- 如果 `daily-logs.json` 不存在，自动创建 `{"logs": []}`
- 如果 `drafts/` 目录不存在，自动创建空目录

### 数据流

```
Claude Code 编辑 JSON/MD 文件
        ↓
文件系统触发变化事件
        ↓
App 检测到变化，防抖后重新加载
        ↓
解析 JSON / 读取 MD，更新数据模型
        ↓
SwiftUI @Published 触发 UI 刷新
```

App 内编辑同理：修改 → 写文件 → 触发重新加载 → UI 刷新，保持单一数据源。

### 核心模块

| 模块 | 职责 |
|------|------|
| `DataStore` | 数据加载、解析、持久化，@Published 属性驱动 UI |
| `FileWatcher` | 封装 FSEvents，递归监听数据目录变化，防抖后回调通知 DataStore |
| `ProjectListView` | 左侧边栏，项目列表与筛选 |
| `ProjectDetailView` | 项目详情，含子任务和草稿 tab |
| `CalendarMonthView` | 月视图日历网格 |
| `DayDetailView` | 日详情，展示当天工作记录 |
| `MarkdownEditorView` | 草稿的 Markdown 渲染与编辑 |
| `SettingsView` | 设置页，选择数据目录 |

## CLAUDE.md 提示词

项目数据目录下放置 `CLAUDE.md`，指导 Claude Code 如何操作数据：

```markdown
# WorkTracker 数据操作指南

数据目录：当前目录

## 文件结构
- projects.json：所有项目和子任务
- daily-logs.json：每日工作记录
- drafts/<项目id>.md：项目草稿

## 常见操作
- "这周在做 XX 项目"：在 projects.json 中新增或更新项目
- "XX 项目目前在等客户确认"：更新对应项目的 currentStatus
- "今天花了3小时做 XX"：在 daily-logs.json 中添加当天记录
- "帮我在 XX 项目记一下 YY"：追加到 drafts/<项目id>.md

## 数据格式规范
- 项目 id 格式：p<自增数字>，如 p1, p2, p3
- 子任务 id 格式：t<自增数字>，全局唯一
- status 枚举：not_started / in_progress / waiting / done / paused
- priority 枚举：low / medium / high / urgent
- 日期格式：YYYY-MM-DD
- 新增项目时自动分配下一个可用 id
- 更新时只修改相关字段，保留其他字段不变
- 写 JSON 时使用 2 空格缩进，保持可读性
- 如果 drafts/ 目录不存在，先创建再写入
```
