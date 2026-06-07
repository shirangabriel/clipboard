import SwiftUI

struct ClipboardRow: View {
    let icon: String?
    let value: String
    let isFavorite: Bool
    let copy: (String) -> Void
    let delete: () -> Void
    let toggleFavorite: () -> Void

    init(
        icon: String? = nil,
        value: String,
        isFavorite: Bool,
        copy: @escaping (String) -> Void,
        delete: @escaping () -> Void,
        toggleFavorite: @escaping () -> Void
    ) {
        self.icon = icon
        self.value = value
        self.isFavorite = isFavorite
        self.copy = copy
        self.delete = delete
        self.toggleFavorite = toggleFavorite
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
                Button(favoriteActionLabel, systemImage: favoriteIcon, action: toggleFavorite)
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            }

            IconButton(systemName: favoriteIcon, label: favoriteActionLabel, action: toggleFavorite)
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

    private var favoriteIcon: String {
        isFavorite ? "star.fill" : "star"
    }

    private var favoriteActionLabel: String {
        isFavorite ? "Remove Favorite" : "Add to Favorites"
    }
}
