import SwiftUI

struct DayDetailView: View {
    let date: String
    let onBack: () -> Void
    let onProjectTap: (String) -> Void
    @EnvironmentObject var store: DataStore
    @State private var editingId: String?
    @State private var editSummary = ""
    @State private var editManDays = ""

    var entries: [LogEntry] {
        store.logsForDate(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Label("返回月视图", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                Spacer()
                Text(date)
                    .font(.headline)
            }
            .padding(8)

            if entries.isEmpty {
                ContentUnavailableView("当天无工作记录", systemImage: "calendar.badge.exclamationmark")
                    .frame(height: 150)
            } else {
                List(entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(store.projectName(for: entry.projectId))
                                    .fontWeight(.medium)
                                if let taskId = entry.taskId,
                                   let taskName = store.taskName(for: taskId) {
                                    Text("/ \(taskName)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(entry.summary)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let md = entry.manDays {
                            Text(String(format: "%.1f人天", md))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("删除", role: .destructive) {
                            store.deleteLogEntry(date: date, entryId: entry.id)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }
}
