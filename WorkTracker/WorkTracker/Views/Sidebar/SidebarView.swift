import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selection: SidebarItem?
    @State private var statusFilter: ProjectStatus?
    @State private var priorityFilter: Priority?
    @State private var sortOption: ProjectSortOption = .status
    @State private var showNewProject = false
    // P2-A: 删除确认对话框所需状态
    @State private var projectToDelete: String?
    @State private var showDeleteConfirmation = false

    var filteredProjects: [Project] {
        SidebarProjectQuery.projects(
            from: store.projects,
            statusFilter: statusFilter,
            priorityFilter: priorityFilter,
            sortOption: sortOption
        )
    }

    var hasActiveFilters: Bool {
        SidebarProjectQuery.hasActiveFilters(
            statusFilter: statusFilter,
            priorityFilter: priorityFilter
        )
    }

    var body: some View {
        List(selection: $selection) {
            Label("日历", systemImage: "calendar")
                .tag(SidebarItem.calendar)

            Section("项目") {
                ForEach(filteredProjects) { project in
                    ProjectRowView(project: project)
                        .tag(SidebarItem.project(project.id))
                        .contextMenu {
                            // P2-A: 不直接删除，先弹确认对话框
                            Button("删除项目", role: .destructive) {
                                projectToDelete = project.id
                                showDeleteConfirmation = true
                            }
                        }
                }
            }
        }
        // P1-C: source list 样式，启用 vibrancy 磨砂背景
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top) {
            HStack {
                Menu {
                    ForEach(ProjectSortOption.allCases, id: \.self) { option in
                        Button { sortOption = option } label: {
                            menuItemLabel(option.label, selected: sortOption == option)
                        }
                    }
                } label: {
                    toolbarButtonLabel(
                        systemImage: SidebarToolbarPresentation.sortButtonSystemImage,
                        title: SidebarToolbarPresentation.sortButtonTitle
                    )
                }
                .help(SidebarToolbarPresentation.sortButtonHelp(sortOption: sortOption))
                .fixedSize()

                Menu {
                    Menu("状态筛选") {
                        Button { statusFilter = nil } label: {
                            menuItemLabel("全部", selected: statusFilter == nil)
                        }
                        Divider()
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Button { statusFilter = status } label: {
                                menuItemLabel(status.label, selected: statusFilter == status)
                            }
                        }
                    }

                    Menu("优先级筛选") {
                        Button { priorityFilter = nil } label: {
                            menuItemLabel("全部", selected: priorityFilter == nil)
                        }
                        Divider()
                        ForEach(Priority.allCases.reversed(), id: \.self) { priority in
                            Button { priorityFilter = priority } label: {
                                menuItemLabel(priority.label, selected: priorityFilter == priority)
                            }
                        }
                    }

                    if hasActiveFilters {
                        Divider()
                        Button("清除筛选") {
                            statusFilter = nil
                            priorityFilter = nil
                        }
                    }
                } label: {
                    toolbarButtonLabel(
                        systemImage: SidebarToolbarPresentation.filterButtonSystemImage(
                            hasActiveFilters: hasActiveFilters
                        ),
                        title: SidebarToolbarPresentation.filterButtonTitle
                    )
                }
                .help(
                    SidebarToolbarPresentation.filterButtonHelp(
                        statusFilter: statusFilter,
                        priorityFilter: priorityFilter
                    )
                )
                .fixedSize()

                Spacer()
                Button(action: { showNewProject = true }) {
                    Image(systemName: "plus")
                }
                .help("新建项目")
            }
            .padding(8)
        }
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet { project in
                store.addProject(project)
                selection = .project(project.id)
            }
        }
        // P2-A: 删除确认 alert，presenting 保证关闭前 id 不丢失
        .alert("删除项目", isPresented: $showDeleteConfirmation, presenting: projectToDelete) { id in
            Button("删除", role: .destructive) {
                store.deleteProject(id: id)
                if selection == .project(id) {
                    selection = .calendar
                }
            }
            Button("取消", role: .cancel) {}
        } message: { _ in
            Text("此操作可通过 ⌘Z 撤销。")
        }
        .onReceive(NotificationCenter.default.publisher(for: .newProjectCommand)) { _ in
            showNewProject = true
        }
    }

    private func toolbarButtonLabel(systemImage: String, title: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.callout)
        .foregroundStyle(Color.primary)
    }

    private func menuItemLabel(_ title: String, selected: Bool) -> some View {
        HStack {
            if selected {
                Image(systemName: "checkmark")
            } else {
                Image(systemName: "checkmark")
                    .hidden()
            }
            Text(title)
        }
    }
}
