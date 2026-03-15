import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject var store: DataStore
    @State private var newTaskName = ""
    @State private var isAddingTask = false
    @FocusState private var isTaskInputFocused: Bool
    @FocusState private var focusedTaskId: String?   // Bug 1: 重命名 TextField 的焦点管理
    @State private var hoveredTaskId: String?
    @State private var editingTaskId: String?
    @State private var editingTaskName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                projectHeader
                Divider()
                taskSection
                Divider()
                draftSection
            }
            .frame(maxWidth: 640, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        // P3-C: contentShape 确保点击区域覆盖整个背景，避免与子视图手势竞争
        .contentShape(Rectangle())
        .onTapGesture {
            commitTaskEdit()
            cancelAddTask()
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }

    // MARK: - Header

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 标题行：左侧色块 + 项目名，右侧状态/优先级
            HStack(alignment: .center) {
                HStack(alignment: .center, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ColorPalette.color(for: project.id))
                        .frame(width: 4, height: 24)
                    SmoothTextField(
                        text: project.name,
                        placeholder: "项目名称",
                        font: .title2.bold()
                    ) { val in updateField { $0.name = val } }
                }
                Spacer(minLength: 12)
                HStack(spacing: 6) {
                    statusMenu
                    priorityMenu
                }
            }

            // 当前进展 callout
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 2)
                SmoothTextField(
                    text: project.currentStatus,
                    placeholder: "当前进展…",
                    font: .subheadline
                ) { val in updateField { $0.currentStatus = val } }
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 7))

            // 日期行：开始 → 截止（→ 完成）
            HStack(spacing: 10) {
                InlineDatePicker(
                    dateString: project.startDate,
                    label: "开始日期",
                    icon: "calendar"
                ) { val in updateField { $0.startDate = val } }

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)

                InlineDatePicker(
                    dateString: project.dueDate ?? "",
                    label: "截止日期",
                    icon: "flag"
                ) { val in updateField { $0.dueDate = val.isEmpty ? nil : val } }

                if project.status == .done || project.completedDate != nil {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 1, height: 12)
                    InlineDatePicker(
                        dateString: project.completedDate ?? "",
                        label: "完成日期",
                        icon: "checkmark.circle"
                    ) { val in updateField { $0.completedDate = val.isEmpty ? nil : val } }
                }
            }


            // 标签
            InlineTagsEditor(tags: project.tags) { newTags in
                updateField { $0.tags = newTags }
            }

            // 描述
            SmoothTextField(
                text: project.description,
                placeholder: "添加项目描述…",
                font: .callout,
                color: .secondary
            ) { val in updateField { $0.description = val } }
        }
        .padding(24)
    }

    // MARK: - Menus

    private var statusMenu: some View {
        Menu {
            ForEach(ProjectStatus.allCases, id: \.self) { s in
                Button(action: { changeStatus(s) }) {
                    HStack {
                        Text(s.label)
                        if s == project.status { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            Text(project.status.label)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(ColorPalette.statusColor(project.status).opacity(0.15))
                .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var priorityMenu: some View {
        Menu {
            ForEach(Priority.allCases, id: \.self) { p in
                Button(action: { changePriority(p) }) {
                    HStack {
                        Text(p.label)
                        if p == project.priority { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            Text(project.priority.label)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(ColorPalette.priorityColor(project.priority).opacity(0.15))
                .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - Task Section

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section 标题
            HStack {
                Text("子任务")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Spacer()
                if !project.tasks.isEmpty {
                    let done = project.tasks.filter { $0.status == .done }.count
                    Text("\(done) / \(project.tasks.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // 任务行
            ForEach(project.tasks) { task in
                taskRow(task)
                if task.id != project.tasks.last?.id {
                    Divider().padding(.leading, 56)
                }
            }

            if !project.tasks.isEmpty {
                Divider().padding(.leading, 56)  // Bug 2: 与任务间分隔线保持一致
            }

            // 添加子任务：点击按钮后内联展开输入行
            if isAddingTask {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.body)
                    TextField("任务名称", text: $newTaskName)
                        .textFieldStyle(.plain)
                        .focused($isTaskInputFocused)
                        .onSubmit { submitTask() }
                        .onExitCommand { cancelAddTask() }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 9)
                .padding(.bottom, 5)
            } else {
                Button {
                    isAddingTask = true
                    isTaskInputFocused = true
                } label: {
                    Label("添加子任务", systemImage: "plus")
                        .foregroundStyle(Color.secondary)
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.vertical, 9)
                .padding(.bottom, 5)
            }
        }
    }

    private func taskRow(_ task: ProjectTask) -> some View {
        HStack(spacing: 10) {
            Button(action: { toggleTaskStatus(task.id) }) {
                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.status == .done ? Color.green : Color.secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)

            if editingTaskId == task.id {
                TextField("任务名称", text: $editingTaskName)
                    .textFieldStyle(.plain)
                    .focused($focusedTaskId, equals: task.id)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(nsColor: .textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1)
                            )
                    )
                    // TextField 进入视图树后立即聚焦，比 DispatchQueue 更可靠
                    .onAppear { focusedTaskId = task.id }
                    .onSubmit { commitTaskEdit() }
                    .onExitCommand { editingTaskId = nil }
            } else {
                Text(task.name)
                    .strikethrough(task.status == .done)
                    .foregroundStyle(task.status == .done ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .onTapGesture(count: 2) {
                        editingTaskId = task.id
                        editingTaskName = task.name
                        // 焦点由 TextField.onAppear 负责设置
                    }
            }

            Spacer()

            if task.status != .done && editingTaskId != task.id {
                Text(task.status.label)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ColorPalette.statusColor(task.status).opacity(0.12))
                    .clipShape(Capsule())
            }

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(hoveredTaskId == task.id ? Color.primary.opacity(0.04) : Color.clear)
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.12)) {
                hoveredTaskId = hovered ? task.id : nil
            }
        }
        .contextMenu {
            Button(task.status == .done ? "标记未完成" : "标记完成") {
                toggleTaskStatus(task.id)
            }
            Button("重命名") {
                editingTaskId = task.id
                editingTaskName = task.name
            }
            Divider()
            Button("删除", role: .destructive) {
                deleteTask(task.id)
            }
        }
    }

    // MARK: - Draft Section

    private var draftSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("草稿")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 8)

            DraftEditorView(projectId: project.id)
                .frame(minHeight: 180)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Actions

    private func updateField(_ transform: (inout Project) -> Void) {
        var updated = project
        transform(&updated)
        store.updateProject(updated)
    }

    private func changeStatus(_ newStatus: ProjectStatus) {
        updateField {
            guard newStatus != $0.status else { return }  // T9: 防重复追加
            $0.status = newStatus
            $0.statusHistory.append(StatusChange(status: newStatus, date: DateHelpers.today()))
            if newStatus == .done {
                $0.completedDate = DateHelpers.today()
            } else {
                $0.completedDate = nil
            }
        }
    }

    private func changePriority(_ newPriority: Priority) {
        updateField { $0.priority = newPriority }
    }

    private func submitTask() {
        let name = newTaskName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            cancelAddTask()
            return
        }
        var updated = project
        let task = ProjectTask(
            id: store.nextTaskId(),
            name: name, status: .notStarted, currentStatus: ""
        )
        updated.tasks.append(task)
        store.updateProject(updated)
        newTaskName = ""
        // 提交后保持输入行展开，便于连续录入
        isTaskInputFocused = true
    }

    private func cancelAddTask() {
        newTaskName = ""
        isAddingTask = false
    }

    private func deleteTask(_ taskId: String) {
        updateField { $0.tasks.removeAll { $0.id == taskId } }
    }

    private func toggleTaskStatus(_ taskId: String) {
        updateField { p in
            if let idx = p.tasks.firstIndex(where: { $0.id == taskId }) {
                p.tasks[idx].status = p.tasks[idx].status == .done ? .notStarted : .done
            }
        }
    }

    private func commitTaskEdit() {
        guard let taskId = editingTaskId else { return }
        let name = editingTaskName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            updateField { p in
                if let idx = p.tasks.firstIndex(where: { $0.id == taskId }) {
                    p.tasks[idx].name = name
                }
            }
        }
        editingTaskId = nil
    }
}

// MARK: - Smooth TextField

struct SmoothTextField: View {
    let text: String
    let placeholder: String
    let font: Font
    var color: Color = .primary
    let onCommit: (String) -> Void

    @State private var draft: String = ""
    @State private var hasAppeared = false
    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $draft)
            .font(font)
            .foregroundStyle(color)
            .textFieldStyle(.plain)
            .focused($focused)
            .onSubmit { commit() }
            .onExitCommand { draft = text }
            .onChange(of: focused) { _, newVal in
                if !newVal { commit() }
            }
            .onAppear {
                draft = text
                hasAppeared = true
            }
            .onChange(of: text) { _, newVal in
                if !focused { draft = newVal }
            }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        if trimmed != text { onCommit(trimmed) }
    }
}

// MARK: - Inline Tags Editor

struct InlineTagsEditor: View {
    let tags: [String]
    let onUpdate: ([String]) -> Void

    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        if isEditing {
            TextField("用逗号分隔标签", text: $draft)
                .font(.caption)
                .textFieldStyle(.plain)
                .focused($focused)
                .onSubmit { commit() }
                .onExitCommand { isEditing = false }
                .onChange(of: focused) { _, newVal in
                    if !newVal { commit() }
                }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if tags.isEmpty {
                    Text("添加标签…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
                }
            }
            .onTapGesture {
                draft = tags.joined(separator: ", ")
                isEditing = true
                focused = true
            }
        }
    }

    private func commit() {
        let newTags = draft.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if newTags != tags { onUpdate(newTags) }
        isEditing = false
    }
}

// MARK: - Inline Date Picker

struct InlineDatePicker: View {
    let dateString: String
    let label: String
    let icon: String
    let onCommit: (String) -> Void

    @State private var pickerDate = Date()
    @State private var hasDate: Bool = false
    @State private var showPicker = false

    private static let storeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let displayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            if hasDate {
                Text(Self.displayFmt.string(from: pickerDate))
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .onTapGesture { showPicker.toggle() }
                    .popover(isPresented: $showPicker) {
                        DatePicker(
                            "",
                            selection: $pickerDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding(8)
                        .onChange(of: pickerDate) { _, newVal in
                            onCommit(Self.storeFmt.string(from: newVal))
                        }
                    }

                Button(action: {
                    hasDate = false
                    onCommit("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            } else {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .onTapGesture {
                        let today = Date()
                        pickerDate = today
                        hasDate = true
                        showPicker = true
                        onCommit(Self.storeFmt.string(from: today))
                    }
            }
        }
        .onAppear {
            if let d = Self.storeFmt.date(from: dateString) {
                pickerDate = d
                hasDate = true
            } else {
                hasDate = !dateString.isEmpty
            }
        }
    }
}
