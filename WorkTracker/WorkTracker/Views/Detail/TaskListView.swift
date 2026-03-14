import SwiftUI

struct TaskListView: View {
    let tasks: [ProjectTask]
    var onAdd: ((String) -> Void)?
    var onDelete: ((String) -> Void)?
    var onToggleStatus: ((String) -> Void)?
    @State private var newTaskName = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        List {
            ForEach(tasks) { task in
                taskRow(task)
                    .contextMenu {
                        if let onToggleStatus = onToggleStatus {
                            Button(task.status == .done ? "标记未完成" : "标记完成") {
                                onToggleStatus(task.id)
                            }
                        }
                        Divider()
                        if let onDelete = onDelete {
                            Button("删除任务", role: .destructive) {
                                onDelete(task.id)
                            }
                        }
                    }
            }

            // 内联添加行
            if let onAdd = onAdd {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(isInputFocused ? Color.accentColor : Color.gray)
                        .font(.body)
                    TextField("添加新任务…", text: $newTaskName)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .onSubmit {
                            submitTask(onAdd)
                        }
                    if !newTaskName.isEmpty {
                        Button(action: { submitTask(onAdd) }) {
                            Text("添加")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        .overlay {
            if tasks.isEmpty && onAdd == nil {
                emptyState
            }
        }
    }

    private func taskRow(_ task: ProjectTask) -> some View {
        HStack(spacing: 8) {
            Button(action: { onToggleStatus?(task.id) }) {
                Image(systemName: task.status == .done
                      ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(ColorPalette.statusColor(task.status))
                    .font(.body)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .strikethrough(task.status == .done)
                    .foregroundStyle(task.status == .done ? .secondary : .primary)
                if !task.currentStatus.isEmpty {
                    Text(task.currentStatus)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if task.status != .done {
                Text(task.status.label)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ColorPalette.statusColor(task.status).opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
            Text("暂无子任务")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func submitTask(_ onAdd: (String) -> Void) {
        let name = newTaskName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        onAdd(name)
        newTaskName = ""
        isInputFocused = true
    }
}
