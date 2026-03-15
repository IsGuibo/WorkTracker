import SwiftUI

struct DraftEditorView: View {
    let projectId: String
    @EnvironmentObject var store: DataStore
    @State private var content: String = ""
    // P3-B（并发）: 用可取消的 Task 替代 Foundation Timer，统一到 Swift 并发模型
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        TextEditor(text: $content)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(8)
            .overlay(alignment: .topLeading) {
                if content.isEmpty {
                    Text("在此撰写草稿…")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .onAppear { loadDraft() }
            .onDisappear {
                // Task.cancel() 自动跳过待执行的保存，无需手动 nil 判断
                saveTask?.cancel()
                saveTask = nil
            }
            .onChange(of: projectId) { _, _ in loadDraft() }   // T8: 新版 API
            .onChange(of: content) { _, _ in scheduleSave() }  // T8: 新版 API
    }

    private func loadDraft() {
        content = store.loadDraft(projectId: projectId) ?? ""
    }

    private func scheduleSave() {
        saveTask?.cancel()
        // @MainActor 继承调用上下文，Task.sleep 挂起但不阻塞主线程
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            store.saveDraft(projectId: projectId, content: content)
        }
    }
}
