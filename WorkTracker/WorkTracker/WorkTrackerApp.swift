import SwiftUI
import AppKit

@main
struct WorkTrackerApp: App {
    @StateObject private var dataStore: DataStore

    init() {
        let path = UserDefaults.standard.string(forKey: "dataDirectoryPath") ?? ""
        let dir: URL
        if path.isEmpty {
            dir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("WorkTracker")
        } else {
            dir = URL(fileURLWithPath: path)
        }
        _dataStore = StateObject(wrappedValue: DataStore(directory: dir))
    }

    var body: some Scene {
        WindowGroup("工作追踪") {
            ContentView()
                .environmentObject(dataStore)
                .onAppear {
                    dataStore.loadAll()
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    // 覆盖菜单栏左上角的应用名
                    DispatchQueue.main.async {
                        NSApp.mainMenu?.items.first?.title = "工作追踪"
                    }
                }
        }
        .defaultSize(width: 1100, height: 700)
        Settings {
            SettingsView()
        }
    }
}
