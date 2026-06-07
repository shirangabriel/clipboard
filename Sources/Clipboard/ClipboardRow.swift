import SwiftUI

struct ClipboardRow: View {
    let icon: String?
    let value: String
    let copy: (String) -> Void
    let delete: () -> Void
    let favorite: () -> Void

    init(
        icon: String? = nil,
        value: String,
        copy: @escaping (String) -> Void,
        delete: @escaping () -> Void,
        favorite: @escaping () -> Void
    ) {
        self.icon = icon
        self.value = value
        self.copy = copy
        self.delete = delete
        self.favorite = favorite
    }

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
        .frame(height: 30)
        .padding(.horizontal, 2)
        .background(isHovering ? AppTheme.hover : Color.clear)
        .clipShape(.rect(cornerRadius: 6))
        .onHover { isHovering = $0 }
    }

    private var rowLabel: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.secondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)
            }

            Text(value.menuPreview)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
    }
}
