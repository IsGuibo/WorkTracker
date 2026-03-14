import SwiftUI

struct TaskListView: View {
    let tasks: [ProjectTask]

    var body: some View {
        if tasks.isEmpty {
            ContentUnavailableView("暂无子任务", systemImage: "checklist")
        } else {
            List(tasks) { task in
                HStack {
                    Image(systemName: task.status == .done
                          ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(ColorPalette.statusColor(task.status))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.name)
                            .strikethrough(task.status == .done)
                        Text(task.currentStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(task.status.rawValue.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ColorPalette.statusColor(task.status).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
