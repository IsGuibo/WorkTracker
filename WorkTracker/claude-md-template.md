# WorkTracker 数据操作指南

数据目录：当前目录

## 文件结构
- projects.json：所有项目和子任务
- daily-logs.json：每日工作记录
- drafts/<项目id>.md：项目草稿

## 常见操作
- "这周在做 XX 项目"：在 projects.json 中新增或更新项目
- "XX 项目目前在等客户确认"：更新对应项目的 currentStatus 和 status
- "XX 项目暂停了"：status 改为 paused，statusHistory 追加一条 paused 记录
- "XX 项目恢复了"：status 改为 in_progress，statusHistory 追加一条 in_progress 记录
- "今天花了3小时做 XX"：在 daily-logs.json 中添加当天记录
- "帮我在 XX 项目记一下 YY"：追加到 drafts/<项目id>.md

## 数据格式规范
- 项目 id 格式：p<自增数字>，如 p1, p2, p3
- 子任务 id 格式：t<自增数字>，全局唯一（跨项目不重复）
- status 枚举：not_started / in_progress / waiting / done / paused
- priority 枚举：low / medium / high / urgent
- 日期格式：YYYY-MM-DD
- 新增项目时自动分配下一个可用 id
- 更新时只修改相关字段，保留其他字段不变
- 写 JSON 时使用 2 空格缩进，保持可读性
- 如果 drafts/ 目录不存在，先创建再写入
- 每次修改 status 时，必须同时往 statusHistory 追加一条记录
