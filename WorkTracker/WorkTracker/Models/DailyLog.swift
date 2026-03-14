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
