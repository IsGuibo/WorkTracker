# WorkTracker 实现计划

> **自动化执行提示：** 必须使用 superpowers:subagent-driven-development（如有子代理）或 superpowers:executing-plans 来执行此计划。步骤使用 checkbox (`- [ ]`) 语法跟踪进度。

**目标：** 构建一个 SwiftUI macOS 原生应用，从本地 JSON/Markdown 文件读取并展示工作进度，通过实时文件监听响应 Claude Code 的数据更新。

**架构：** NavigationSplitView 布局，左侧边栏（项目列表）+ 右侧详情区（项目详情 / 日历视图）。数据层使用 ObservableObject DataStore 加载 JSON 文件，通过 FSEvents 监听文件变化。所有数据以本地文件持久化，无数据库。

**技术栈：** Swift, SwiftUI, macOS 14+, Xcode, Swift Package Manager, FSEvents (CoreServices)

**设计文档：** `docs/superpowers/specs/2026-03-14-worktracker-design.md`

---

## 文件结构

```
WorkTracker/
├── WorkTracker.xcodeproj
├── WorkTracker/
│   ├── WorkTrackerApp.swift              # 应用入口，窗口配置
│   ├── ContentView.swift                 # 根布局 NavigationSplitView
│   ├── Models/
│   │   ├── Project.swift                 # 项目、子任务、状态变更模型
│   │   ├── DailyLog.swift                # 每日记录、日志条目模型
│   │   └── Enums.swift                   # ProjectStatus、Priority 枚举
│   ├── Services/
│   │   ├── DataStore.swift               # ObservableObject，加载/保存/监听
│   │   └── FileWatcher.swift             # FSEvents 封装，带防抖
│   ├── Views/
│   │   ├── Sidebar/
│   │   │   ├── ProjectListView.swift     # 项目列表，带筛选
│   │   │   └── ProjectRowView.swift      # 侧边栏单个项目行
│   │   ├── Detail/
│   │   │   ├── ProjectDetailView.swift   # 项目信息 + 标签页
│   │   │   ├── TaskListView.swift        # 子任务列表标签页
│   │   │   └── DraftEditorView.swift     # Markdown 草稿标签页
│   │   ├── Calendar/
│   │   │   ├── CalendarMonthView.swift   # 月视图网格 + 甘特条
│   │   │   ├── GanttBarView.swift        # 单个项目时间线条
│   │   │   └── DayDetailView.swift       # 日详情，展示工作记录
│   │   └── Settings/
│   │       └── SettingsView.swift        # 数据目录选择
│   └── Utilities/
│       ├── ColorPalette.swift            # 项目颜色分配
│       └── DateHelpers.swift             # 日期格式化/计算工具
├── WorkTrackerTests/
│   ├── ModelTests.swift                  # JSON 编解码测试
│   ├── DataStoreTests.swift              # DataStore 加载/保存测试
│   └── CalendarHelperTests.swift         # 日期计算测试
└── CLAUDE.md                             # Claude Code 数据操作指南
```

---

## Chunk 1: 项目搭建 + 数据模型 + DataStore

### Task 1: 创建 Xcode 项目

**文件：**
- 创建: `WorkTracker/` Xcode 项目结构

- [ ] **Step 1: 通过命令行创建项目结构**

创建一个新的 SwiftUI macOS 应用项目，手动创建目录结构：

```bash
mkdir -p WorkTracker/WorkTracker
mkdir -p WorkTracker/WorkTrackerTests
```

创建 `WorkTracker/WorkTracker/WorkTrackerApp.swift`：
```swift
import SwiftUI

@main
struct WorkTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1100, height: 700)
        Settings {
            SettingsView()
        }
    }
}
```

创建 `WorkTracker/WorkTracker/ContentView.swift`：
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("WorkTracker")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

创建占位 `WorkTracker/WorkTracker/Views/Settings/SettingsView.swift`：
```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .frame(width: 400, height: 200)
    }
}
```

- [ ] **Step 2: 创建 Xcode 项目文件**

使用 Xcode 创建 `.xcodeproj`（或用 `swift package init` 后转换）。设置部署目标为 macOS 14.0。确保项目能构建运行，显示 "WorkTracker" 文字。

- [ ] **Step 3: 提交**

```bash
git add WorkTracker/
git commit -m "feat: 搭建 Xcode 项目，SwiftUI 应用入口"
```

---

### Task 2: 定义数据模型

**文件：**
- 创建: `WorkTracker/WorkTracker/Models/Enums.swift`
- 创建: `WorkTracker/WorkTracker/Models/Project.swift`
- 创建: `WorkTracker/WorkTracker/Models/DailyLog.swift`
- 创建: `WorkTracker/WorkTrackerTests/ModelTests.swift`

- [ ] **Step 1: 编写模型测试**

创建 `WorkTracker/WorkTrackerTests/ModelTests.swift`：
```swift
import XCTest
@testable import WorkTracker

final class ModelTests: XCTestCase {

    func testDecodeProject() throws {
        let json = """
        {
          "id": "p1", "name": "DP项目", "status": "in_progress",
          "priority": "high", "tags": ["定开"],
          "currentStatus": "等客户确认",
          "startDate": "2026-03-10",
          "statusHistory": [{"status": "in_progress", "date": "2026-03-10"}],
          "description": "DP定开项目", "tasks": []
        }
        """.data(using: .utf8)!
        let project = try JSONDecoder().decode(Project.self, from: json)
        XCTAssertEqual(project.id, "p1")
        XCTAssertEqual(project.status, .inProgress)
        XCTAssertEqual(project.priority, .high)
        XCTAssertEqual(project.statusHistory.count, 1)
        XCTAssertNil(project.dueDate)
    }

    func testDecodeProjectWithPauseHistory() throws {
        let json = """
        {
          "id": "p2", "name": "Test", "status": "paused",
          "priority": "low", "tags": [], "currentStatus": "暂停中",
          "startDate": "2026-03-01", "dueDate": "2026-04-01",
          "statusHistory": [
            {"status": "in_progress", "date": "2026-03-01"},
            {"status": "paused", "date": "2026-03-15"}
          ],
          "description": "",
          "tasks": [{"id": "t1", "name": "子任务1", "status": "done", "currentStatus": "完成"}]
        }
        """.data(using: .utf8)!
        let project = try JSONDecoder().decode(Project.self, from: json)
        XCTAssertEqual(project.statusHistory.count, 2)
        XCTAssertEqual(project.tasks.count, 1)
    }

    func testDecodeDailyLogs() throws {
        let json = """
        {
          "logs": [{
            "date": "2026-03-14",
            "entries": [{"projectId": "p1", "summary": "完成接口改造", "hoursSpent": 4}]
          }]
        }
        """.data(using: .utf8)!
        let container = try JSONDecoder().decode(DailyLogContainer.self, from: json)
        XCTAssertEqual(container.logs.count, 1)
        XCTAssertNil(container.logs[0].entries[0].taskId)
    }

    func testEncodeProject() throws {
        let project = Project(
            id: "p1", name: "Test", status: .inProgress, priority: .medium,
            tags: [], currentStatus: "进行中", startDate: "2026-03-10",
            dueDate: nil,
            statusHistory: [StatusChange(status: .inProgress, date: "2026-03-10")],
            description: "", tasks: []
        )
        let data = try JSONEncoder().encode(project)
        let str = String(data: data, encoding: .utf8)!
        XCTAssertTrue(str.contains("in_progress"))
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: 失败 — 模型尚未定义。

- [ ] **Step 3: 实现 Enums.swift**

创建 `WorkTracker/WorkTracker/Models/Enums.swift`：
```swift
import Foundation

enum ProjectStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case waiting, done, paused
}

enum Priority: String, Codable, CaseIterable, Comparable {
    case low, medium, high, urgent

    private var sortOrder: Int {
        switch self {
        case .low: 0; case .medium: 1; case .high: 2; case .urgent: 3
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
```

- [ ] **Step 4: 实现 Project.swift**

创建 `WorkTracker/WorkTracker/Models/Project.swift`：
```swift
import Foundation

struct StatusChange: Codable, Identifiable {
    var id: String { "\(status.rawValue)-\(date)" }
    let status: ProjectStatus
    let date: String
}

struct ProjectTask: Codable, Identifiable {
    let id: String
    var name: String
    var status: ProjectStatus
    var currentStatus: String
}

struct Project: Codable, Identifiable {
    let id: String
    var name: String
    var status: ProjectStatus
    var priority: Priority
    var tags: [String]
    var currentStatus: String
    var startDate: String
    var dueDate: String?
    var statusHistory: [StatusChange]
    var description: String
    var tasks: [ProjectTask]
}

struct ProjectContainer: Codable {
    var projects: [Project]
}
```

- [ ] **Step 5: 实现 DailyLog.swift**

创建 `WorkTracker/WorkTracker/Models/DailyLog.swift`：
```swift
import Foundation

struct LogEntry: Codable, Identifiable {
    var id: String { "\(projectId)-\(summary)" }
    let projectId: String
    var taskId: String?
    var summary: String
    var hoursSpent: Double?
}

struct DailyLog: Codable, Identifiable {
    var id: String { date }
    let date: String
    var entries: [LogEntry]
}

struct DailyLogContainer: Codable {
    var logs: [DailyLog]
}
```

- [ ] **Step 6: 运行测试验证通过**

```bash
xcodebuild test -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: 全部通过

- [ ] **Step 7: 提交**

```bash
git add WorkTracker/
git commit -m "feat: 添加数据模型，含 JSON 编解码和测试"
```

---

### Task 3: 实现 FileWatcher

**文件：**
- 创建: `WorkTracker/WorkTracker/Services/FileWatcher.swift`

- [ ] **Step 1: 实现 FileWatcher**

创建 `WorkTracker/WorkTracker/Services/FileWatcher.swift`：
```swift
import Foundation
import CoreServices

final class FileWatcher {
    private var stream: FSEventStreamRef?
    private let callback: () -> Void
    private let debounceInterval: TimeInterval
    private var debounceWorkItem: DispatchWorkItem?

    init(directory: URL, debounceInterval: TimeInterval = 0.3,
         callback: @escaping () -> Void) {
        self.callback = callback
        self.debounceInterval = debounceInterval
        startWatching(directory: directory)
    }

    private func startWatching(directory: URL) {
        let pathsToWatch = [directory.path as CFString] as CFArray
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(
            nil,
            { (_, info, _, _, _, _) in
                guard let info else { return }
                Unmanaged<FileWatcher>.fromOpaque(info)
                    .takeUnretainedValue().handleEvent()
            },
            &context, pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.1,
            UInt32(kFSEventStreamCreateFlagUseCFTypes |
                   kFSEventStreamCreateFlagFileEvents |
                   kFSEventStreamCreateFlagNoDefer)
        ) else { return }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    private func handleEvent() {
        debounceWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.callback() }
        debounceWorkItem = item
        DispatchQueue.main.asyncAfter(
            deadline: .now() + debounceInterval, execute: item)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit { stop() }
}
```

- [ ] **Step 2: 构建验证编译通过**

```bash
xcodebuild build -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
git add WorkTracker/WorkTracker/Services/FileWatcher.swift
git commit -m "feat: 添加 FSEvents 文件监听器，带防抖"
```

---

### Task 4: 实现 DataStore

**文件：**
- 创建: `WorkTracker/WorkTracker/Services/DataStore.swift`
- 创建: `WorkTracker/WorkTrackerTests/DataStoreTests.swift`

- [ ] **Step 1: 编写 DataStore 测试**

创建 `WorkTracker/WorkTrackerTests/DataStoreTests.swift`：
```swift
import XCTest
@testable import WorkTracker

final class DataStoreTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    @MainActor
    func testInitCreatesEmptyFiles() {
        let store = DataStore(directory: tempDir, enableFileWatcher: false)
        store.loadAll()
        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(
            atPath: tempDir.appendingPathComponent("projects.json").path))
        XCTAssertTrue(fm.fileExists(
            atPath: tempDir.appendingPathComponent("daily-logs.json").path))
        XCTAssertTrue(fm.fileExists(
            atPath: tempDir.appendingPathComponent("drafts").path))
    }

    @MainActor
    func testLoadProjects() throws {
        let json = """
        {"projects": [{"id": "p1", "name": "Test", "status": "in_progress",
        "priority": "high", "tags": [], "currentStatus": "doing",
        "startDate": "2026-03-10",
        "statusHistory": [{"status": "in_progress", "date": "2026-03-10"}],
        "description": "", "tasks": []}]}
        """.data(using: .utf8)!
        try json.write(to: tempDir.appendingPathComponent("projects.json"))
        let store = DataStore(directory: tempDir, enableFileWatcher: false)
        store.loadAll()
        XCTAssertEqual(store.projects.count, 1)
        XCTAssertEqual(store.projects[0].name, "Test")
    }

    @MainActor
    func testLoadInvalidJSONKeepsLastValid() throws {
        let valid = """
        {"projects": [{"id": "p1", "name": "Valid", "status": "done",
        "priority": "low", "tags": [], "currentStatus": "done",
        "startDate": "2026-01-01",
        "statusHistory": [{"status": "done", "date": "2026-01-01"}],
        "description": "", "tasks": []}]}
        """.data(using: .utf8)!
        try valid.write(to: tempDir.appendingPathComponent("projects.json"))
        let store = DataStore(directory: tempDir, enableFileWatcher: false)
        store.loadAll()
        XCTAssertEqual(store.projects.count, 1)

        try "{ broken".data(using: .utf8)!
            .write(to: tempDir.appendingPathComponent("projects.json"))
        store.loadAll()
        XCTAssertEqual(store.projects.count, 1)
        XCTAssertTrue(store.hasError)
    }

    @MainActor
    func testDraftReadWrite() throws {
        let store = DataStore(directory: tempDir, enableFileWatcher: false)
        store.loadAll()
        store.saveDraft(projectId: "p1", content: "# Draft")
        XCTAssertEqual(store.loadDraft(projectId: "p1"), "# Draft")
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: 失败 — DataStore 尚未定义。

- [ ] **Step 3: 实现 DataStore**

创建 `WorkTracker/WorkTracker/Services/DataStore.swift`：
```swift
import Foundation
import SwiftUI

@MainActor
final class DataStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var dailyLogs: [DailyLog] = []
    @Published var hasError = false
    @Published var errorMessage = ""

    let directory: URL
    private var fileWatcher: FileWatcher?

    init(directory: URL, enableFileWatcher: Bool = true) {
        self.directory = directory
        if enableFileWatcher {
            fileWatcher = FileWatcher(directory: directory) { [weak self] in
                Task { @MainActor in self?.loadAll() }
            }
        }
    }

    func loadAll() {
        ensureDirectoryStructure()
        loadProjects()
        loadDailyLogs()
    }

    private func ensureDirectoryStructure() {
        let fm = FileManager.default
        let pFile = directory.appendingPathComponent("projects.json")
        let lFile = directory.appendingPathComponent("daily-logs.json")
        let dDir = directory.appendingPathComponent("drafts")
        if !fm.fileExists(atPath: pFile.path) {
            try? "{\"projects\":[]}".data(using: .utf8)?.write(to: pFile)
        }
        if !fm.fileExists(atPath: lFile.path) {
            try? "{\"logs\":[]}".data(using: .utf8)?.write(to: lFile)
        }
        if !fm.fileExists(atPath: dDir.path) {
            try? fm.createDirectory(at: dDir, withIntermediateDirectories: true)
        }
    }

    private func loadProjects() {
        let url = directory.appendingPathComponent("projects.json")
        guard let data = try? Data(contentsOf: url) else { return }
        do {
            projects = try JSONDecoder()
                .decode(ProjectContainer.self, from: data).projects
            hasError = false; errorMessage = ""
        } catch {
            hasError = true
            errorMessage = "projects.json 解析失败: \(error.localizedDescription)"
            retryAfterDelay { [weak self] in self?.loadProjects() }
        }
    }

    private func loadDailyLogs() {
        let url = directory.appendingPathComponent("daily-logs.json")
        guard let data = try? Data(contentsOf: url) else { return }
        do {
            dailyLogs = try JSONDecoder()
                .decode(DailyLogContainer.self, from: data).logs
        } catch {
            hasError = true
            errorMessage = "daily-logs.json 解析失败: \(error.localizedDescription)"
            retryAfterDelay { [weak self] in self?.loadDailyLogs() }
        }
    }

    private func retryAfterDelay(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { action() }
    }

    func loadDraft(projectId: String) -> String? {
        let url = directory.appendingPathComponent("drafts/\(projectId).md")
        return try? String(contentsOf: url, encoding: .utf8)
    }

    func saveDraft(projectId: String, content: String) {
        let dir = directory.appendingPathComponent("drafts")
        try? FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true)
        try? content.write(
            to: dir.appendingPathComponent("\(projectId).md"),
            atomically: true, encoding: .utf8)
    }

    func saveProjects() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(
            ProjectContainer(projects: projects)) else { return }
        try? data.write(to: directory.appendingPathComponent("projects.json"))
    }

    func logsForDate(_ date: String) -> [LogEntry] {
        dailyLogs.first { $0.date == date }?.entries ?? []
    }

    func projectName(for id: String) -> String {
        projects.first { $0.id == id }?.name ?? id
    }

    func taskName(for taskId: String) -> String? {
        projects.flatMap(\.tasks).first { $0.id == taskId }?.name
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: 全部通过

- [ ] **Step 5: 提交**

```bash
git add WorkTracker/
git commit -m "feat: 添加 DataStore，含文件加载、错误处理和测试"
```

---

## Chunk 2: 侧边栏 + 项目详情 + 设置页

### Task 5: 工具类

**文件：**
- 创建: `WorkTracker/WorkTracker/Utilities/ColorPalette.swift`
- 创建: `WorkTracker/WorkTracker/Utilities/DateHelpers.swift`

- [ ] **Step 1: 实现 ColorPalette**

创建 `WorkTracker/WorkTracker/Utilities/ColorPalette.swift`：
```swift
import SwiftUI

enum ColorPalette {
    static let colors: [Color] = [
        .blue, .purple, .orange, .green, .pink,
        .cyan, .indigo, .mint, .teal, .brown
    ]

    static func color(for projectId: String) -> Color {
        let hash = abs(projectId.hashValue)
        return colors[hash % colors.count]
    }

    static func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .notStarted: .gray
        case .inProgress: .blue
        case .waiting: .orange
        case .done: .green
        case .paused: .secondary
        }
    }

    static func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: .gray
        case .medium: .blue
        case .high: .orange
        case .urgent: .red
        }
    }
}
```

- [ ] **Step 2: 实现 DateHelpers**

创建 `WorkTracker/WorkTracker/Utilities/DateHelpers.swift`：
```swift
import Foundation

enum DateHelpers {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func parse(_ string: String) -> Date? {
        formatter.date(from: string)
    }

    static func format(_ date: Date) -> String {
        formatter.string(from: date)
    }

    static func today() -> String {
        format(Date())
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    static func firstWeekdayOfMonth(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { return 1 }
        return calendar.component(.weekday, from: date)
    }
}
```

- [ ] **Step 3: 写日期工具测试**

创建 `WorkTracker/WorkTrackerTests/CalendarHelperTests.swift`：
```swift
import XCTest
@testable import WorkTracker

final class CalendarHelperTests: XCTestCase {
    func testParseAndFormat() {
        let date = DateHelpers.parse("2026-03-14")
        XCTAssertNotNil(date)
        XCTAssertEqual(DateHelpers.format(date!), "2026-03-14")
    }

    func testDaysInMonth() {
        XCTAssertEqual(DateHelpers.daysInMonth(year: 2026, month: 2), 28)
        XCTAssertEqual(DateHelpers.daysInMonth(year: 2026, month: 3), 31)
    }

    func testFirstWeekday() {
        // 2026-03-01 是周日
        let weekday = DateHelpers.firstWeekdayOfMonth(year: 2026, month: 3)
        XCTAssertEqual(weekday, 1) // Sunday = 1
    }
}
```

- [ ] **Step 4: 运行测试**

```bash
xcodebuild test -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: ALL PASS

- [ ] **Step 5: 提交**

```bash
git add WorkTracker/
git commit -m "feat: 添加颜色调色板和日期工具类"
```

---

### Task 6: 设置页 — 数据目录选择

**文件：**
- 修改: `WorkTracker/WorkTracker/Views/Settings/SettingsView.swift`
- 修改: `WorkTracker/WorkTracker/WorkTrackerApp.swift`

- [ ] **Step 1: 实现 SettingsView**

修改 `WorkTracker/WorkTracker/Views/Settings/SettingsView.swift`：
```swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("dataDirectoryPath") private var dataDirectoryPath: String = ""

    var body: some View {
        Form {
            Section("数据目录") {
                HStack {
                    Text(dataDirectoryPath.isEmpty ? "未设置" : dataDirectoryPath)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("选择文件夹") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.message = "选择 WorkTracker 数据目录"
                        if panel.runModal() == .OK, let url = panel.url {
                            dataDirectoryPath = url.path
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 150)
    }
}
```

- [ ] **Step 2: 更新 WorkTrackerApp 接入 DataStore**

修改 `WorkTracker/WorkTracker/WorkTrackerApp.swift`：
```swift
import SwiftUI

@main
struct WorkTrackerApp: App {
    @AppStorage("dataDirectoryPath") private var dataDirectoryPath: String = ""

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataStore)
        }
        .defaultSize(width: 1100, height: 700)
        Settings {
            SettingsView()
        }
    }

    private var dataStore: DataStore {
        let dir: URL
        if dataDirectoryPath.isEmpty {
            dir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("WorkTracker")
        } else {
            dir = URL(fileURLWithPath: dataDirectoryPath)
        }
        let store = DataStore(directory: dir)
        store.loadAll()
        return store
    }
}
```

注意：上面的 `dataStore` 计算属性每次都会创建新实例，实际实现时需要用 `@StateObject` 或 `@State` 持有。实现时改为：

```swift
@main
struct WorkTrackerApp: App {
    @StateObject private var dataStore: DataStore

    init() {
        let path = UserDefaults.standard.string(forKey: "dataDirectoryPath") ?? ""
        let dir: URL
        if path.isEmpty {
            dir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("WorkTracker")
        } else {
            dir = URL(fileURLWithPath: path)
        }
        _dataStore = StateObject(wrappedValue: DataStore(directory: dir))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
        .defaultSize(width: 1100, height: 700)
        Settings {
            SettingsView()
        }
    }
}
```

- [ ] **Step 3: 构建验证**

```bash
xcodebuild build -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: BUILD SUCCEEDED

- [ ] **Step 4: 提交**

```bash
git add WorkTracker/
git commit -m "feat: 添加设置页数据目录选择，接入 DataStore"
```

---

### Task 7: 项目列表侧边栏

**文件：**
- 创建: `WorkTracker/WorkTracker/Views/Sidebar/ProjectRowView.swift`
- 创建: `WorkTracker/WorkTracker/Views/Sidebar/ProjectListView.swift`
- 修改: `WorkTracker/WorkTracker/ContentView.swift`

- [ ] **Step 1: 实现 ProjectRowView**

创建 `WorkTracker/WorkTracker/Views/Sidebar/ProjectRowView.swift`：
```swift
import SwiftUI

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(ColorPalette.color(for: project.id))
                    .frame(width: 8, height: 8)
                Text(project.name)
                    .fontWeight(.medium)
                Spacer()
                Text(project.status.rawValue.replacingOccurrences(of: "_", with: " "))
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ColorPalette.statusColor(project.status).opacity(0.15))
                    .foregroundStyle(ColorPalette.statusColor(project.status))
                    .clipShape(Capsule())
            }
            Text(project.currentStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: 实现 ProjectListView**

创建 `WorkTracker/WorkTracker/Views/Sidebar/ProjectListView.swift`：
```swift
import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedProjectId: String?
    @State private var statusFilter: ProjectStatus?
    @State private var priorityFilter: Priority?

    var filteredProjects: [Project] {
        store.projects.filter { p in
            if let s = statusFilter, p.status != s { return false }
            if let pr = priorityFilter, p.priority != pr { return false }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            HStack {
                Menu("状态") {
                    Button("全部") { statusFilter = nil }
                    Divider()
                    ForEach(ProjectStatus.allCases, id: \.self) { s in
                        Button(s.rawValue) { statusFilter = s }
                    }
                }
                Menu("优先级") {
                    Button("全部") { priorityFilter = nil }
                    Divider()
                    ForEach(Priority.allCases, id: \.self) { p in
                        Button(p.rawValue) { priorityFilter = p }
                    }
                }
                Spacer()
            }
            .padding(8)

            List(filteredProjects, selection: $selectedProjectId) { project in
                ProjectRowView(project: project)
                    .tag(project.id)
            }
        }
    }
}
```

- [ ] **Step 3: 更新 ContentView 为 NavigationSplitView**

修改 `WorkTracker/WorkTracker/ContentView.swift`：
```swift
import SwiftUI

enum MainViewMode {
    case projectDetail
    case calendar
}

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedProjectId: String?
    @State private var viewMode: MainViewMode = .projectDetail

    var body: some View {
        NavigationSplitView {
            ProjectListView(selectedProjectId: $selectedProjectId)
        } detail: {
            VStack(spacing: 0) {
                // 工具栏
                HStack {
                    Text(store.directory.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Picker("视图", selection: $viewMode) {
                        Text("项目").tag(MainViewMode.projectDetail)
                        Text("日历").tag(MainViewMode.calendar)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                .padding(8)

                // 错误提示
                if store.hasError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(store.errorMessage)
                        Spacer()
                    }
                    .padding(8)
                    .background(.red.opacity(0.1))
                    .foregroundStyle(.red)
                }

                // 主内容
                switch viewMode {
                case .projectDetail:
                    if let id = selectedProjectId,
                       let project = store.projects.first(where: { $0.id == id }) {
                        ProjectDetailView(project: project)
                    } else {
                        ContentUnavailableView("选择一个项目", systemImage: "folder")
                    }
                case .calendar:
                    Text("日历视图（待实现）")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}
```

- [ ] **Step 4: 构建验证**

```bash
xcodebuild build -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: BUILD SUCCEEDED（ProjectDetailView 还没实现，先用占位）

注意：如果 ProjectDetailView 未定义导致编译失败，先创建占位：
```swift
struct ProjectDetailView: View {
    let project: Project
    var body: some View { Text(project.name) }
}
```

- [ ] **Step 5: 提交**

```bash
git add WorkTracker/
git commit -m "feat: 添加项目列表侧边栏和 NavigationSplitView 布局"
```

---

### Task 8: 项目详情页（子任务 + 草稿）

**文件：**
- 创建: `WorkTracker/WorkTracker/Views/Detail/ProjectDetailView.swift`
- 创建: `WorkTracker/WorkTracker/Views/Detail/TaskListView.swift`
- 创建: `WorkTracker/WorkTracker/Views/Detail/DraftEditorView.swift`

- [ ] **Step 1: 实现 TaskListView**

创建 `WorkTracker/WorkTracker/Views/Detail/TaskListView.swift`：
```swift
import SwiftUI

struct TaskListView: View {
    let tasks: [ProjectTask]

    var body: some View {
        if tasks.isEmpty {
            ContentUnavailableView("暂无子任务", systemImage: "checklist")
        } else {
            List(tasks) { task in
                HStack {
                    Image(systemName: task.status == .done
                          ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(ColorPalette.statusColor(task.status))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.name)
                            .strikethrough(task.status == .done)
                        Text(task.currentStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(task.status.rawValue.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ColorPalette.statusColor(task.status).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
```

- [ ] **Step 2: 实现 DraftEditorView**

创建 `WorkTracker/WorkTracker/Views/Detail/DraftEditorView.swift`：
```swift
import SwiftUI

struct DraftEditorView: View {
    let projectId: String
    @EnvironmentObject var store: DataStore
    @State private var content: String = ""
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(isEditing ? "保存" : "编辑") {
                    if isEditing {
                        store.saveDraft(projectId: projectId, content: content)
                    }
                    isEditing.toggle()
                }
            }
            .padding(8)

            if isEditing {
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
            } else if content.isEmpty {
                ContentUnavailableView("暂无草稿", systemImage: "doc.text")
            } else {
                ScrollView {
                    Text(LocalizedStringKey(content))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .onAppear { loadDraft() }
        .onChange(of: projectId) { loadDraft() }
    }

    private func loadDraft() {
        content = store.loadDraft(projectId: projectId) ?? ""
        isEditing = false
    }
}
```

- [ ] **Step 3: 实现 ProjectDetailView**

创建（或替换占位）`WorkTracker/WorkTracker/Views/Detail/ProjectDetailView.swift`：
```swift
import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @State private var selectedTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 项目信息卡片
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(ColorPalette.color(for: project.id))
                        .frame(width: 12, height: 12)
                    Text(project.name)
                        .font(.title2.bold())
                    Spacer()
                    Text(project.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ColorPalette.priorityColor(project.priority).opacity(0.15))
                        .clipShape(Capsule())
                    Text(project.status.rawValue.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ColorPalette.statusColor(project.status).opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(project.currentStatus)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    if !project.startDate.isEmpty {
                        Label(project.startDate, systemImage: "calendar")
                            .font(.caption)
                    }
                    if let due = project.dueDate {
                        Label(due, systemImage: "flag")
                            .font(.caption)
                    }
                }

                if !project.tags.isEmpty {
                    HStack {
                        ForEach(project.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }

                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Tab 切换
            Picker("", selection: $selectedTab) {
                Text("子任务").tag(0)
                Text("草稿").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Tab 内容
            switch selectedTab {
            case 0:
                TaskListView(tasks: project.tasks)
            case 1:
                DraftEditorView(projectId: project.id)
            default:
                EmptyView()
            }
        }
    }
}
```

- [ ] **Step 4: 构建并运行验证**

```bash
xcodebuild build -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: BUILD SUCCEEDED

- [ ] **Step 5: 提交**

```bash
git add WorkTracker/
git commit -m "feat: 添加项目详情页，含子任务列表和草稿编辑器"
```

---

## Chunk 3: 日历月视图 + 甘特时间线 + 日详情 + CLAUDE.md

### Task 9: 日历月视图网格

**文件：**
- 创建: `WorkTracker/WorkTracker/Views/Calendar/CalendarMonthView.swift`

- [ ] **Step 1: 实现 CalendarMonthView**

创建 `WorkTracker/WorkTracker/Views/Calendar/CalendarMonthView.swift`：
```swift
import SwiftUI

struct CalendarMonthView: View {
    @EnvironmentObject var store: DataStore
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDate: String?
    @Binding var selectedProjectId: String?
    @Binding var viewMode: MainViewMode

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 0) {
            // 月份导航
            HStack {
                Button(action: prevMonth) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text("\(String(year))年\(month)月")
                    .font(.title3.bold())
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            // 星期标题
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // 日期网格
            let days = generateDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(days, id: \.self) { day in
                    if day == 0 {
                        Color.clear.frame(height: 32)
                    } else {
                        let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
                        let hasLogs = !store.logsForDate(dateStr).isEmpty
                        Button(action: {
                            selectedDate = dateStr
                        }) {
                            Text("\(day)")
                                .font(.callout)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(hasLogs ? Color.accentColor.opacity(0.1) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)

            Divider().padding(.vertical, 8)

            // 甘特时间线区域
            GanttBarView(
                year: year, month: month,
                projects: store.projects,
                onProjectTap: { projectId in
                    selectedProjectId = projectId
                    viewMode = .projectDetail
                }
            )

            Spacer()

            // 日详情（选中日期时显示）
            if let date = selectedDate {
                Divider()
                DayDetailView(
                    date: date,
                    onBack: { selectedDate = nil },
                    onProjectTap: { projectId in
                        selectedProjectId = projectId
                        viewMode = .projectDetail
                    }
                )
            }
        }
    }

    private func generateDays() -> [Int] {
        let firstWeekday = DateHelpers.firstWeekdayOfMonth(year: year, month: month)
        let daysCount = DateHelpers.daysInMonth(year: year, month: month)
        var days: [Int] = Array(repeating: 0, count: firstWeekday - 1)
        days += Array(1...daysCount)
        return days
    }

    private func prevMonth() {
        if month == 1 { year -= 1; month = 12 } else { month -= 1 }
        selectedDate = nil
    }

    private func nextMonth() {
        if month == 12 { year += 1; month = 1 } else { month += 1 }
        selectedDate = nil
    }
}
```

- [ ] **Step 2: 构建验证（GanttBarView 和 DayDetailView 先用占位）**

创建占位文件：

`WorkTracker/WorkTracker/Views/Calendar/GanttBarView.swift`：
```swift
import SwiftUI

struct GanttBarView: View {
    let year: Int
    let month: Int
    let projects: [Project]
    let onProjectTap: (String) -> Void
    var body: some View { EmptyView() }
}
```

`WorkTracker/WorkTracker/Views/Calendar/DayDetailView.swift`：
```swift
import SwiftUI

struct DayDetailView: View {
    let date: String
    let onBack: () -> Void
    let onProjectTap: (String) -> Void
    var body: some View { Text(date) }
}
```

```bash
xcodebuild build -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: BUILD SUCCEEDED

- [ ] **Step 3: 更新 ContentView 接入日历视图**

修改 `ContentView.swift` 中 `case .calendar:` 部分：
```swift
case .calendar:
    CalendarMonthView(
        selectedProjectId: $selectedProjectId,
        viewMode: $viewMode
    )
```

- [ ] **Step 4: 提交**

```bash
git add WorkTracker/
git commit -m "feat: 添加日历月视图网格和月份导航"
```

---

### Task 10: 甘特时间线

**文件：**
- 修改: `WorkTracker/WorkTracker/Views/Calendar/GanttBarView.swift`

- [ ] **Step 1: 实现 GanttBarView**

替换 `WorkTracker/WorkTracker/Views/Calendar/GanttBarView.swift`：
```swift
import SwiftUI

struct GanttBarView: View {
    let year: Int
    let month: Int
    let projects: [Project]
    let onProjectTap: (String) -> Void

    private var daysInMonth: Int {
        DateHelpers.daysInMonth(year: year, month: month)
    }

    private var monthStart: String {
        String(format: "%04d-%02d-01", year, month)
    }

    private var monthEnd: String {
        String(format: "%04d-%02d-%02d", year, month, daysInMonth)
    }

    /// 筛选出在当月有活动段的项目
    private var visibleProjects: [Project] {
        projects.filter { project in
            !segments(for: project).isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if visibleProjects.isEmpty {
                Text("当月无项目时间线")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(visibleProjects) { project in
                    ganttRow(for: project)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func ganttRow(for project: Project) -> some View {
        GeometryReader { geo in
            let dayWidth = geo.size.width / CGFloat(daysInMonth)
            ZStack(alignment: .leading) {
                ForEach(segments(for: project), id: \.startDay) { seg in
                    let x = dayWidth * CGFloat(seg.startDay - 1)
                    let w = dayWidth * CGFloat(seg.endDay - seg.startDay + 1)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ColorPalette.color(for: project.id)
                            .opacity(project.status == .done ? 0.4 : 0.8))
                        .frame(width: max(w, 4), height: 18)
                        .offset(x: x)
                        .overlay(alignment: .leading) {
                            if w > 50 {
                                Text(project.name)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .padding(.leading, 4)
                                    .offset(x: x)
                            }
                        }
                }
            }
        }
        .frame(height: 22)
        .contentShape(Rectangle())
        .onTapGesture { onProjectTap(project.id) }
    }

    struct Segment {
        let startDay: Int
        let endDay: Int
    }

    /// 根据 statusHistory 计算当月内的活跃段（in_progress 状态的时间段）
    private func segments(for project: Project) -> [Segment] {
        let history = project.statusHistory.sorted { $0.date < $1.date }
        guard !history.isEmpty else { return [] }

        var result: [Segment] = []
        let today = DateHelpers.today()

        for i in 0..<history.count {
            let entry = history[i]
            // 只画 in_progress 段
            guard entry.status == .inProgress else { continue }

            let segStart = entry.date
            let segEnd: String
            if i + 1 < history.count {
                // 下一个状态变更的前一天
                segEnd = history[i + 1].date
            } else if project.status == .inProgress {
                // 当前仍在进行中，延伸到 dueDate 或今天
                segEnd = project.dueDate ?? today
            } else {
                segEnd = entry.date
            }

            // 裁剪到当月范围
            let clampedStart = max(segStart, monthStart)
            let clampedEnd = min(segEnd, monthEnd)
            guard clampedStart <= clampedEnd else { continue }

            if let startDay = dayOfMonth(clampedStart),
               let endDay = dayOfMonth(clampedEnd) {
                result.append(Segment(startDay: startDay, endDay: endDay))
            }
        }
        return result
    }

    private func dayOfMonth(_ dateStr: String) -> Int? {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3, let d = Int(parts[2]) else { return nil }
        return min(d, daysInMonth)
    }
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild build -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
git add WorkTracker/WorkTracker/Views/Calendar/GanttBarView.swift
git commit -m "feat: 实现甘特时间线，支持 statusHistory 分段渲染"
```

---

### Task 11: 日详情视图

**文件：**
- 修改: `WorkTracker/WorkTracker/Views/Calendar/DayDetailView.swift`

- [ ] **Step 1: 实现 DayDetailView**

替换 `WorkTracker/WorkTracker/Views/Calendar/DayDetailView.swift`：
```swift
import SwiftUI

struct DayDetailView: View {
    let date: String
    let onBack: () -> Void
    let onProjectTap: (String) -> Void
    @EnvironmentObject var store: DataStore

    var entries: [LogEntry] {
        store.logsForDate(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Label("返回月视图", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                Spacer()
                Text(date)
                    .font(.headline)
            }
            .padding(8)

            if entries.isEmpty {
                ContentUnavailableView("当天无工作记录", systemImage: "calendar.badge.exclamationmark")
                    .frame(height: 150)
            } else {
                List(entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(store.projectName(for: entry.projectId))
                                    .fontWeight(.medium)
                                if let taskId = entry.taskId,
                                   let taskName = store.taskName(for: taskId) {
                                    Text("/ \(taskName)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(entry.summary)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let hours = entry.hoursSpent {
                            Text("\(hours, specifier: "%.1f")h")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onProjectTap(entry.projectId) }
                }
                .frame(height: 200)
            }
        }
    }
}
```

- [ ] **Step 2: 构建验证**

```bash
xcodebuild build -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
git add WorkTracker/WorkTracker/Views/Calendar/DayDetailView.swift
git commit -m "feat: 实现日详情视图，展示当天工作记录"
```

---

### Task 12: 创建 CLAUDE.md 数据操作指南

**文件：**
- 创建: `CLAUDE.md`（数据目录下，由 App 首次启动时创建，或手动放置）

- [ ] **Step 1: 创建 CLAUDE.md**

在项目根目录创建一个模板文件 `WorkTracker/claude-md-template.md`，App 初始化数据目录时可以复制过去：
```markdown
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
```

- [ ] **Step 2: 提交**

```bash
git add WorkTracker/claude-md-template.md
git commit -m "feat: 添加 CLAUDE.md 数据操作指南模板"
```

---

### Task 13: 最终集成验证

- [ ] **Step 1: 全量构建**

```bash
xcodebuild build -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: BUILD SUCCEEDED

- [ ] **Step 2: 运行全部测试**

```bash
xcodebuild test -project WorkTracker/WorkTracker.xcodeproj -scheme WorkTracker -destination 'platform=macOS'
```
预期: ALL PASS

- [ ] **Step 3: 手动验证**

准备测试数据，在 `~/WorkTracker/` 下放入示例 JSON，启动 App 验证：
1. 侧边栏显示项目列表，筛选功能正常
2. 点击项目显示详情，子任务和草稿 tab 切换正常
3. 日历月视图显示甘特时间线，暂停项目有空白段
4. 点击日期显示日详情
5. 修改 JSON 文件后 App 自动刷新

- [ ] **Step 4: 最终提交**

```bash
git add -A
git commit -m "feat: WorkTracker v1 完成，集成验证通过"
```
