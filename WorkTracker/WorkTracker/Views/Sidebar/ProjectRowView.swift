import SwiftUI

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(ColorPalette.color(for: project.id))
                    .frame(width: 8, height: 8)
                Text(project.name)
                    .fontWeight(.medium)
                Spacer()
                Text(project.status.label)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ColorPalette.statusColor(project.status).opacity(0.15))
                    .foregroundStyle(ColorPalette.statusColor(project.status))
                    .clipShape(Capsule())
            }
            Text(project.currentStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.leading, 16)
        }
        .padding(.vertical, 4)
    }
}
