import SwiftUI

struct FavoriteRow: View {
    let favorite: FavoriteItem
    let copy: (String) -> Void
    let remove: () -> Void
    let rename: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                copy(favorite.value)
            } label: {
                rowLabel
            }
            .buttonStyle(.plain)
            .help(favorite.value)
            .accessibilityLabel("Copy favorite \(favorite.slot), shortcut Control Option Command \(favorite.slot)")
            .frame(maxWidth: .infinity)
            .contextMenu {
                Button("Copy", action: { copy(favorite.value) })
                Button("Rename", systemImage: "pencil", action: rename)
                Button("Remove Favorite", systemImage: "star.fill", role: .destructive, action: remove)
            }

            IconButton(systemName: "star.fill", label: "Remove Favorite", action: remove)
        }
        .frame(height: 30)
        .padding(.horizontal, 2)
        .background(isHovering ? AppTheme.hover : Color.clear)
        .clipShape(.rect(cornerRadius: 6))
        .onHover { isHovering = $0 }
    }

    private var rowLabel: some View {
        HStack(spacing: 12) {
            Text("\(favorite.slot)")
                .font(.caption)
                .bold()
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20, height: 20)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppTheme.primary, lineWidth: 1.5)
                }
                .accessibilityLabel("Favorite \(favorite.slot)")

            Text(favorite.displayName.menuPreview)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
    }
}
