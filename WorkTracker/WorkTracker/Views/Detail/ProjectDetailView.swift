import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @State private var selectedTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(ColorPalette.color(for: project.id))
                        .frame(width: 12, height: 12)
                    Text(project.name)
                        .font(.title2.bold())
                    Spacer()
                    Text(project.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ColorPalette.priorityColor(project.priority).opacity(0.15))
                        .clipShape(Capsule())
                    Text(project.status.rawValue.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ColorPalette.statusColor(project.status).opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(project.currentStatus)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    if !project.startDate.isEmpty {
                        Label(project.startDate, systemImage: "calendar")
                            .font(.caption)
                    }
                    if let due = project.dueDate {
                        Label(due, systemImage: "flag")
                            .font(.caption)
                    }
                }

                if !project.tags.isEmpty {
                    HStack {
                        ForEach(project.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }

                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            Picker("", selection: $selectedTab) {
                Text("子任务").tag(0)
                Text("草稿").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case 0:
                TaskListView(tasks: project.tasks)
            case 1:
                DraftEditorView(projectId: project.id)
            default:
                EmptyView()
            }
        }
    }
}
