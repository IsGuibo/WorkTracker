import Foundation

struct LogEntry: Codable, Identifiable {
    var id: String
    var projectId: String
    var taskId: String?
    var summary: String
    var manDays: Double?

    init(projectId: String, taskId: String?, summary: String, manDays: Double?) {
        self.id = UUID().uuidString
        self.projectId = projectId
        self.taskId = taskId
        self.summary = summary
        self.manDays = manDays
    }

    // 旧数据没有 id 字段时自动生成
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        projectId = try c.decode(String.self, forKey: .projectId)
        taskId = try c.decodeIfPresent(String.self, forKey: .taskId)
        summary = try c.decode(String.self, forKey: .summary)
        manDays = try c.decodeIfPresent(Double.self, forKey: .manDays)
    }
}

struct DailyLog: Codable, Identifiable {
    var id: String { date }
    let date: String
    var entries: [LogEntry]
}

struct DailyLogContainer: Codable {
    var logs: [DailyLog]
}
