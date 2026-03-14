import Foundation

enum ProjectStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case paused, done

    var label: String {
        switch self {
        case .notStarted: "未开始"
        case .inProgress: "进行中"
        case .paused: "暂停"
        case .done: "已完成"
        }
    }

    // 兼容旧数据：waiting → paused
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if raw == "waiting" {
            self = .paused
        } else {
            self = ProjectStatus(rawValue: raw) ?? .notStarted
        }
    }
}

enum Priority: String, Codable, CaseIterable, Comparable {
    case low, medium, high, urgent

    var label: String {
        switch self {
        case .low: "低"
        case .medium: "中"
        case .high: "高"
        case .urgent: "紧急"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .low: 0; case .medium: 1; case .high: 2; case .urgent: 3
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
