import SwiftUI

struct ClipboardRow: View {
    let icon: String
    let value: String
    let copy: (String) -> Void
    let delete: () -> Void
    let favorite: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                copy(value)
            } label: {
                rowLabel
            }
            .buttonStyle(.plain)
            .help(value)
            .frame(maxWidth: .infinity)
            .contextMenu {
                Button("Copy", action: { copy(value) })
                Button("Add to Favorites", systemImage: "star", action: favorite)
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            }

            IconButton(systemName: "star", label: "Add to Favorites", action: favorite)
            IconButton(systemName: "trash", label: "Delete", action: delete)
        }
        .frame(height: 31)
        .padding(.horizontal, 4)
        .background(isHovering ? AppTheme.hover : Color.clear)
        .clipShape(.rect(cornerRadius: 8))
        .onHover { isHovering = $0 }
    }

    private var rowLabel: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(value.menuPreview)
                .font(.callout)
                .foregroundStyle(AppTheme.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
    }
}
