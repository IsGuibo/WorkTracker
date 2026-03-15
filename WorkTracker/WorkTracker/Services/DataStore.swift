import Foundation
import SwiftUI

@MainActor
final class DataStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var dailyLogs: [DailyLog] = []
    @Published var hasError = false
    @Published var errorMessage = ""
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    let directory: URL
    let undoManager = UndoManager()
    private var fileWatcher: FileWatcher?
    private var pendingIgnoreCount = 0  // T2: 计数器替换布尔，防竞态

    init(directory: URL, enableFileWatcher: Bool = true) {
        self.directory = directory
        if enableFileWatcher {
            fileWatcher = FileWatcher(directory: directory) { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    if self.pendingIgnoreCount > 0 {  // T2
                        self.pendingIgnoreCount -= 1
                        return
                    }
                    self.loadAll()
                }
            }
        }
    }

    // MARK: - Undo State

    private func syncUndoState() {
        canUndo = undoManager.canUndo
        canRedo = undoManager.canRedo
    }

    // MARK: - T1: ID Helpers

    func nextProjectId() -> String {
        let maxNum = projects.compactMap { p -> Int? in
            guard p.id.hasPrefix("p"), let n = Int(p.id.dropFirst()) else { return nil }
            return n
        }.max() ?? 0
        return "p\(maxNum + 1)"
    }

    func nextTaskId() -> String {
        let maxNum = projects.flatMap(\.tasks).compactMap { t -> Int? in
            guard t.id.hasPrefix("t"), let n = Int(t.id.dropFirst()) else { return nil }
            return n
        }.max() ?? 0
        return "t\(maxNum + 1)"
    }

    // MARK: - Load

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

    private func reportError(_ message: String) {
        hasError = true
        errorMessage = message
    }

    // MARK: - Save (T4: 写入后台, T5: 错误显示到 UI)

    func saveDraft(projectId: String, content: String) {
        let dir = directory.appendingPathComponent("drafts")
        let url = dir.appendingPathComponent("\(projectId).md")
        Task.detached { [self] in
            do {
                try FileManager.default.createDirectory(
                    at: dir, withIntermediateDirectories: true)
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                await self.reportError("草稿保存失败: \(error.localizedDescription)")
            }
        }
    }

    func saveProjects() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(
            ProjectContainer(projects: projects)) else { return }
        pendingIgnoreCount += 1  // T2
        let url = directory.appendingPathComponent("projects.json")
        Task.detached { [self] in
            do {
                try data.write(to: url)
            } catch {
                // 写入失败时归还计数，否则后续外部变更将被永久忽略
                await MainActor.run { self.pendingIgnoreCount -= 1 }
                await self.reportError("保存失败: \(error.localizedDescription)")
            }
        }
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

    // MARK: - 项目操作

    func addProject(_ project: Project) {
        let id = project.id
        undoManager.registerUndo(withTarget: self) { target in
            target.deleteProject(id: id)
        }
        undoManager.setActionName("新建项目")
        projects.append(project)
        saveProjects()
        syncUndoState()
    }

    func deleteProject(id: String) {
        guard let project = projects.first(where: { $0.id == id }) else { return }
        undoManager.registerUndo(withTarget: self) { target in
            target.addProject(project)
        }
        undoManager.setActionName("删除项目")
        projects.removeAll { $0.id == id }
        saveProjects()
        syncUndoState()
    }

    func updateProject(_ project: Project) {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        let old = projects[idx]
        undoManager.registerUndo(withTarget: self) { target in
            target.updateProject(old)
        }
        undoManager.setActionName("修改项目")
        projects[idx] = project
        saveProjects()
        syncUndoState()
    }

    // MARK: - 日志操作

    func saveDailyLogs() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(
            DailyLogContainer(logs: dailyLogs)) else { return }
        pendingIgnoreCount += 1  // T2
        let url = directory.appendingPathComponent("daily-logs.json")
        Task.detached { [self] in
            do {
                try data.write(to: url)
            } catch {
                await MainActor.run { self.pendingIgnoreCount -= 1 }
                await self.reportError("保存失败: \(error.localizedDescription)")
            }
        }
    }

    func addLogEntry(date: String, entry: LogEntry) {
        undoManager.registerUndo(withTarget: self) { target in
            target.deleteLogEntry(date: date, entryId: entry.id)
        }
        undoManager.setActionName("添加工作记录")
        if let idx = dailyLogs.firstIndex(where: { $0.date == date }) {
            dailyLogs[idx].entries.append(entry)
        } else {
            dailyLogs.append(DailyLog(date: date, entries: [entry]))
        }
        saveDailyLogs()
        syncUndoState()
    }

    func deleteLogEntry(date: String, entryId: String) {
        guard let dIdx = dailyLogs.firstIndex(where: { $0.date == date }),
              let entry = dailyLogs[dIdx].entries.first(where: { $0.id == entryId }) else { return }
        undoManager.registerUndo(withTarget: self) { target in
            target.addLogEntry(date: date, entry: entry)
        }
        undoManager.setActionName("删除工作记录")
        dailyLogs[dIdx].entries.removeAll { $0.id == entryId }
        if dailyLogs[dIdx].entries.isEmpty {
            dailyLogs.remove(at: dIdx)
        }
        saveDailyLogs()
        syncUndoState()
    }

    func updateLogEntry(date: String, entry: LogEntry) {
        if let dIdx = dailyLogs.firstIndex(where: { $0.date == date }),
           let eIdx = dailyLogs[dIdx].entries.firstIndex(where: { $0.id == entry.id }) {
            let old = dailyLogs[dIdx].entries[eIdx]
            undoManager.registerUndo(withTarget: self) { target in
                target.updateLogEntry(date: date, entry: old)
            }
            undoManager.setActionName("修改工作记录")
            dailyLogs[dIdx].entries[eIdx] = entry
            saveDailyLogs()
            syncUndoState()
        }
    }
}
