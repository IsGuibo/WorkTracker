import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("dataDirectoryPath") private var dataDirectoryPath: String = ""
    // P2-B: 替换 NSOpenPanel.runModal() 的声明式状态
    @State private var showingFolderPicker = false

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
                        showingFolderPicker = true
                    }
                }
            }
        }
        .formStyle(.grouped)
        // P3-D: 只固定宽度，高度随内容自适应，避免增加设置项时截断
        .frame(width: 450)
        .fixedSize(horizontal: true, vertical: false)
        // P2-B: SwiftUI 原生文件夹选择器，非阻塞，替代 NSOpenPanel.runModal()
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [UTType.folder]
        ) { result in
            if case .success(let url) = result {
                dataDirectoryPath = url.path
            }
        }
    }
}
