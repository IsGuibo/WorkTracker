import SwiftUI

struct DayDetailView: View {
    let date: String
    let onBack: () -> Void
    let onProjectTap: (String) -> Void
    @EnvironmentObject var store: DataStore

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
                        if let hours = entry.hoursSpent {
                            Text("\(hours, specifier: "%.1f")h")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onProjectTap(entry.projectId) }
                }
                .frame(height: 200)
            }
        }
    }
}
