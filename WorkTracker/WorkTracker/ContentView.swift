import SwiftUI

enum SidebarItem: Hashable {
    case calendar
    case project(String)
}

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selection: SidebarItem? = .calendar

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                // P1-C: HIG 推荐侧边栏宽度 180-320pt
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            VStack(spacing: 0) {
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

                switch selection {
                case .calendar:
                    CalendarMonthView(
                        onProjectTap: { id in
                            selection = .project(id)
                        }
                    )
                case .project(let id):
                    if let project = store.projects.first(where: { $0.id == id }) {
                        ProjectDetailView(project: project)
                            .id(project.id)
                    } else {
                        ContentUnavailableView("项目不存在", systemImage: "folder")
                            .frame(maxHeight: .infinity)
                    }
                case nil:
                    ContentUnavailableView("选择一个项目或日历", systemImage: "folder")
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
