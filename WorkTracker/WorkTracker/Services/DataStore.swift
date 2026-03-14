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
