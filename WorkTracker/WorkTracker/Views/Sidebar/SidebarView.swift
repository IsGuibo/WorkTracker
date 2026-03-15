import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selection: SidebarItem?
    @State private var statusFilter: ProjectStatus?
    @State private var priorityFilter: Priority?
    @State private var showNewProject = false

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
                            Button("删除项目", role: .destructive) {
                                store.deleteProject(id: project.id)
                                if selection == .project(project.id) {
                                    selection = .calendar
                                }
                            }
                        }
                }
            }
        }
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
        .onReceive(NotificationCenter.default.publisher(for: .newProjectCommand)) { _ in
            showNewProject = true
        }
    }
}
