import SwiftUI

enum MainViewMode {
    case projectDetail
    case calendar
}

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedProjectId: String?
    @State private var viewMode: MainViewMode = .projectDetail

    var body: some View {
        NavigationSplitView {
            ProjectListView(selectedProjectId: $selectedProjectId)
        } detail: {
            VStack(spacing: 0) {
                HStack {
                    Text(store.directory.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Picker("视图", selection: $viewMode) {
                        Text("项目").tag(MainViewMode.projectDetail)
                        Text("日历").tag(MainViewMode.calendar)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                .padding(8)

                if store.hasError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(store.errorMessage)
                        Spacer()
                    }
                    .padding(8)
                    .background(.red.opacity(0.1))
                    .foregroundStyle(.red)
                }

                switch viewMode {
                case .projectDetail:
                    if let id = selectedProjectId,
                       let project = store.projects.first(where: { $0.id == id }) {
                        ProjectDetailView(project: project)
                    } else {
                        ContentUnavailableView("选择一个项目", systemImage: "folder")
                    }
                case .calendar:
                    CalendarMonthView(
                        selectedProjectId: $selectedProjectId,
                        viewMode: $viewMode
                    )
                }
            }
        }
    }
}
