import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedProjectId: String?
    @State private var statusFilter: ProjectStatus?
    @State private var priorityFilter: Priority?

    var filteredProjects: [Project] {
        store.projects.filter { p in
            if let s = statusFilter, p.status != s { return false }
            if let pr = priorityFilter, p.priority != pr { return false }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Menu("状态") {
                    Button("全部") { statusFilter = nil }
                    Divider()
                    ForEach(ProjectStatus.allCases, id: \.self) { s in
                        Button(s.rawValue) { statusFilter = s }
                    }
                }
                Menu("优先级") {
                    Button("全部") { priorityFilter = nil }
                    Divider()
                    ForEach(Priority.allCases, id: \.self) { p in
                        Button(p.rawValue) { priorityFilter = p }
                    }
                }
                Spacer()
            }
            .padding(8)

            List(filteredProjects, selection: $selectedProjectId) { project in
                ProjectRowView(project: project)
                    .tag(project.id)
            }
        }
    }
}
