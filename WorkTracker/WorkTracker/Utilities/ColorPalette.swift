import SwiftUI

enum ColorPalette {
    // 避开状态色: blue(进行中), orange(等待), green(完成), gray(未开始/暂停)
    // 按色相均匀分布，确保相邻颜色差异明显
    static let projectColors: [Color] = [
        Color(red: 0.86, green: 0.12, blue: 0.18),  // 番茄红   ~0°
        Color(red: 0.90, green: 0.65, blue: 0.05),  // 琥珀黄   ~43°
        Color(red: 0.32, green: 0.74, blue: 0.08),  // 草绿     ~100°
        Color(red: 0.05, green: 0.58, blue: 0.55),  // 青碧     ~177°
        Color(red: 0.10, green: 0.38, blue: 0.80),  // 宝蓝     ~218°
        Color(red: 0.48, green: 0.08, blue: 0.85),  // 紫罗兰   ~270°
        Color(red: 0.83, green: 0.08, blue: 0.65),  // 品红     ~300°
        Color(red: 0.94, green: 0.32, blue: 0.52),  // 玫粉     ~335°
        Color(red: 0.60, green: 0.34, blue: 0.08),  // 棕褐     (暖色系)
        Color(red: 0.68, green: 0.18, blue: 0.32),  // 酒红     (深暗系)
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
        case .paused: .orange
        case .done: .green
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
