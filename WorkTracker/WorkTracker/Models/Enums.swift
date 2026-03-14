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
