import Foundation

enum ProjectStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case waiting, done, paused

    var label: String {
        switch self {
        case .notStarted: "未开始"
        case .inProgress: "进行中"
        case .waiting: "等待中"
        case .done: "已完成"
        case .paused: "已暂停"
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
