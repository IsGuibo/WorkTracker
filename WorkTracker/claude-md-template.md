# WorkTracker 数据操作指南

数据目录：~/WorkTracker

## 文件结构
- projects.json：所有项目和子任务
- daily-logs.json：每日工作记录
- drafts/<项目id>.md：项目草稿（纯文本）

## 数据结构

### projects.json

```json
{
  "projects": [Project]
}
```

**Project**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | 是 | 格式 p<数字>，如 p1, p2 |
| name | string | 是 | 项目名称 |
| status | string | 是 | 枚举：not_started / in_progress / waiting / done / paused |
| priority | string | 是 | 枚举：low / medium / high / urgent |
| tags | [string] | 是 | 标签列表，可为空数组 |
| currentStatus | string | 是 | 当前进展描述，可为空字符串 |
| startDate | string | 是 | 开始日期，格式 YYYY-MM-DD |
| dueDate | string? | 否 | 截止日期，格式 YYYY-MM-DD，可为 null |
| completedDate | string? | 否 | 完成日期，标记完成时自动设置，可手动修改，格式 YYYY-MM-DD |
| description | string | 是 | 项目描述，可为空字符串 |
| statusHistory | [StatusChange] | 是 | 状态变更历史 |
| tasks | [ProjectTask] | 是 | 子任务列表 |

**StatusChange**:
| 字段 | 类型 | 说明 |
|------|------|------|
| status | string | 同 Project.status 枚举 |
| date | string | 变更日期，格式 YYYY-MM-DD |

**ProjectTask**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 格式 t<数字>，全局唯一（跨项目不重复） |
| name | string | 任务名称 |
| status | string | 同 Project.status 枚举 |
| currentStatus | string | 当前状态描述，可为空字符串 |

### daily-logs.json

```json
{
  "logs": [DailyLog]
}
```

**DailyLog**:
| 字段 | 类型 | 说明 |
|------|------|------|
| date | string | 日期，格式 YYYY-MM-DD |
| entries | [LogEntry] | 当天的工作记录列表 |

**LogEntry**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | 是 | UUID 字符串 |
| projectId | string | 是 | 关联的项目 id |
| taskId | string? | 否 | 关联的子任务 id，可为 null |
| summary | string | 是 | 工作内容摘要，可为空字符串 |
| manDays | number? | 否 | 人天数，如 0.5、1.0，可为 null |

### drafts/<项目id>.md

纯文本 Markdown 文件，每个项目一个，文件名为项目 id（如 `drafts/p1.md`）。

## 常见操作
- "这周在做 XX 项目"：在 projects.json 中新增或更新项目
- "XX 项目目前在等客户确认"：更新对应项目的 currentStatus 和 status
- "XX 项目暂停了"：status 改为 paused，statusHistory 追加一条 paused 记录
- "XX 项目恢复了"：status 改为 in_progress，statusHistory 追加一条 in_progress 记录
- "今天花了3小时做 XX"：在 daily-logs.json 中添加当天记录（3小时 ≈ 0.375人天）
- "帮我在 XX 项目记一下 YY"：追加到 drafts/<项目id>.md

## 数据格式规范
- 新增项目时自动分配下一个可用 id（取现有最大数字 +1）
- 更新时只修改相关字段，保留其他字段不变
- 写 JSON 时使用 2 空格缩进，保持可读性
- 如果 drafts/ 目录不存在，先创建再写入
- 每次修改 status 时，必须同时往 statusHistory 追加一条记录
