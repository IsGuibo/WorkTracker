import SwiftUI
import AppKit

extension NSNotification.Name {
    static let newProjectCommand = NSNotification.Name("WorkTracker.newProjectCommand")
}

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
                // P1-B: 设置窗口最小可用尺寸（sidebar 180 + detail 600 + 分隔线）
                .frame(minWidth: 780, minHeight: 500)
                .onAppear {
                    dataStore.loadAll()
                    NSApp.setActivationPolicy(.regular)
                    // P1-A: macOS 14 新 API，不强制抢占其他应用焦点
                    if #available(macOS 14.0, *) {
                        NSApp.activate()
                    } else {
                        NSApp.activate(ignoringOtherApps: false)
                    }
                    // SPM 应用无 Info.plist，通过此方式同步应用菜单标题
                    DispatchQueue.main.async {
                        NSApp.mainMenu?.items.first?.title = "工作追踪"
                    }
                }
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建项目") {
                    NotificationCenter.default.post(
                        name: .newProjectCommand, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        Settings {
            SettingsView()
        }
    }
}
