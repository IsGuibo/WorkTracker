import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selection: SidebarItem?
    @State private var statusFilter: ProjectStatus?
    @State private var priorityFilter: Priority?
    @State private var showNewProject = false
    // P2-A: 删除确认对话框所需状态
    @State private var projectToDelete: String?
    @State private var showDeleteConfirmation = false

    var filteredProjects: [Project] {
        store.projects.filter { p in
            if let s = statusFilter, p.status != s { return false }
            if let pr = priorityFilter, p.priority != pr { return false }
            return true
        }
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
                Menu("状态") {
                    Button("全部") { statusFilter = nil }
                    Divider()
                    ForEach(ProjectStatus.allCases, id: \.self) { s in
                        Button(s.label) { statusFilter = s }
                    }
                }
                Menu("优先级") {
                    Button("全部") { priorityFilter = nil }
                    Divider()
                    ForEach(Priority.allCases, id: \.self) { p in
                        Button(p.label) { priorityFilter = p }
                    }
                }
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
}
