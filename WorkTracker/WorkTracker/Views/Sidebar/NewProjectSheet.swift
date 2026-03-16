import SwiftUI

struct NewProjectSheet: View {
    var onCreate: (Project) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    @State private var name = ""
    @State private var priority: Priority = .medium
    @State private var description = ""
    @State private var tags = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("新建项目")
                .font(.headline)
                .padding(.vertical, 16)

            Divider()

            Form {
                TextField("项目名称", text: $name)
                Picker("优先级", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }
                TextField("描述", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                TextField("标签（逗号分隔）", text: $tags)
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("创建") { createProject() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 400, height: 340)
    }

    private func createProject() {
        let today = DateHelpers.today()
        let id = store.nextProjectId()
        let tagList = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let project = Project(
            id: id, name: name.trimmingCharacters(in: .whitespaces),
            status: .notStarted, priority: priority,
            tags: tagList, currentStatus: "刚创建",
            startDate: today, dueDate: nil,
            statusHistory: [StatusChange(status: .notStarted, date: today)],
            description: description, tasks: []
        )
        onCreate(project)
        dismiss()
    }
}
