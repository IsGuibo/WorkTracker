import SwiftUI

enum ColorPalette {
    // 避开状态色: blue(进行中), orange(等待), green(完成), gray(未开始/暂停)
    static let projectColors: [Color] = [
        .purple, .pink, .indigo, .cyan, .mint,
        .teal, .brown,
        Color(red: 0.8, green: 0.3, blue: 0.4),   // 玫红
        Color(red: 0.4, green: 0.3, blue: 0.7),   // 暗紫
        Color(red: 0.2, green: 0.6, blue: 0.6),   // 青绿
    ]

    static func color(for projectId: String) -> Color {
        let hash = stableHash(projectId)
        return projectColors[hash % projectColors.count]
    }

    /// djb2 确定性哈希，跨进程稳定
    private static func stableHash(_ str: String) -> Int {
        var hash: UInt64 = 5381
        for byte in str.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        return Int(hash % UInt64(Int.max))
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
