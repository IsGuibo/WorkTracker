import SwiftUI

struct DraftEditorView: View {
    let projectId: String
    @EnvironmentObject var store: DataStore
    @State private var content: String = ""
    @State private var saveTimer: Timer?

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
            .onDisappear { saveTimer?.invalidate(); saveTimer = nil }  // T3: 防 Timer 泄漏
            .onChange(of: projectId) { _, _ in loadDraft() }   // T8: 新版 API
            .onChange(of: content) { _, _ in scheduleSave() }  // T8: 新版 API
    }

    private func loadDraft() {
        content = store.loadDraft(projectId: projectId) ?? ""
    }

    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
            Task { @MainActor in
                store.saveDraft(projectId: projectId, content: content)
            }
        }
    }
}
