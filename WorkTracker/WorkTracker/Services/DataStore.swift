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
    private var ignoreNextReload = false

    init(directory: URL, enableFileWatcher: Bool = true) {
        self.directory = directory
        if enableFileWatcher {
            fileWatcher = FileWatcher(directory: directory) { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    if self.ignoreNextReload {
                        self.ignoreNextReload = false
                        return
                    }
                    self.loadAll()
                }
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
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(
            ProjectContainer(projects: projects)) else { return }
        ignoreNextReload = true
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

    // MARK: - 项目操作

    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
    }

    func deleteProject(id: String) {
        projects.removeAll { $0.id == id }
        saveProjects()
    }

    func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            saveProjects()
        }
    }

    // MARK: - 日志操作

    func saveDailyLogs() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(
            DailyLogContainer(logs: dailyLogs)) else { return }
        ignoreNextReload = true
        try? data.write(to: directory.appendingPathComponent("daily-logs.json"))
    }

    func addLogEntry(date: String, entry: LogEntry) {
        if let idx = dailyLogs.firstIndex(where: { $0.date == date }) {
            dailyLogs[idx].entries.append(entry)
        } else {
            dailyLogs.append(DailyLog(date: date, entries: [entry]))
        }
        saveDailyLogs()
    }

    func deleteLogEntry(date: String, entryId: String) {
        if let idx = dailyLogs.firstIndex(where: { $0.date == date }) {
            dailyLogs[idx].entries.removeAll { $0.id == entryId }
            if dailyLogs[idx].entries.isEmpty {
                dailyLogs.remove(at: idx)
            }
            saveDailyLogs()
        }
    }

    func updateLogEntry(date: String, entry: LogEntry) {
        if let dIdx = dailyLogs.firstIndex(where: { $0.date == date }),
           let eIdx = dailyLogs[dIdx].entries.firstIndex(where: { $0.id == entry.id }) {
            dailyLogs[dIdx].entries[eIdx] = entry
            saveDailyLogs()
        }
    }
}
