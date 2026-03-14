import SwiftUI

struct DraftEditorView: View {
    let projectId: String
    @EnvironmentObject var store: DataStore
    @State private var content: String = ""
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(isEditing ? "保存" : "编辑") {
                    if isEditing {
                        store.saveDraft(projectId: projectId, content: content)
                    }
                    isEditing.toggle()
                }
            }
            .padding(8)

            if isEditing {
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
            } else if content.isEmpty {
                ContentUnavailableView("暂无草稿", systemImage: "doc.text")
            } else {
                ScrollView {
                    Text(LocalizedStringKey(content))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .onAppear { loadDraft() }
        .onChange(of: projectId) { loadDraft() }
    }

    private func loadDraft() {
        content = store.loadDraft(projectId: projectId) ?? ""
        isEditing = false
    }
}
