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

    var sidebarSortOrder: Int {
        switch self {
        case .inProgress: 0
        case .notStarted: 1
        case .paused: 2
        case .done: 3
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

    var sidebarSortOrderDescending: Int {
        switch self {
        case .urgent: 0
        case .high: 1
        case .medium: 2
        case .low: 3
        }
    }
}

enum ProjectSortOption: String, CaseIterable {
    case status
    case priority
    case startDate
    case dueDate
    case name

    var label: String {
        switch self {
        case .status: "状态"
        case .priority: "优先级"
        case .startDate: "开始日期"
        case .dueDate: "截止日期"
        case .name: "项目名称"
        }
    }
}
