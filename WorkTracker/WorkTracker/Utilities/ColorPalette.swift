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
