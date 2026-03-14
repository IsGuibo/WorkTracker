import SwiftUI

struct SettingsView: View {
    @AppStorage("dataDirectoryPath") private var dataDirectoryPath: String = ""

    var body: some View {
        Form {
            Section("数据目录") {
                HStack {
                    Text(dataDirectoryPath.isEmpty ? "未设置" : dataDirectoryPath)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("选择文件夹") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.message = "选择 WorkTracker 数据目录"
                        if panel.runModal() == .OK, let url = panel.url {
                            dataDirectoryPath = url.path
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 150)
    }
}
