import SwiftUI

struct FavoritesSectionView: View {
    let favorites: [FavoriteItem]
    @Binding var favoriteBeingRenamed: UUID?
    @Binding var favoriteRenameText: String
    let copy: (String) -> Void
    let deleteFavorite: (UUID) -> Void
    let renameFavorite: (UUID, String) -> Void

    var body: some View {
        SectionBlock(
            title: "Favorites",
            collapsed: false,
            onToggle: nil,
            trailingMenu: {
                favoriteShortcutHint
            }
        ) {
            ForEach(favorites) { favorite in
                if favoriteBeingRenamed == favorite.id {
                    favoriteRenameRow(favorite)
                } else {
                    FavoriteRow(
                        favorite: favorite,
                        copy: copy,
                        remove: { deleteFavorite(favorite.id) },
                        rename: {
                            favoriteBeingRenamed = favorite.id
                            favoriteRenameText = favorite.displayName
                        }
                    )
                }
            }
        }
    }

    private var favoriteShortcutHint: some View {
        Text("⌃⌥⌘1-9")
            .font(.system(size: 11, weight: .medium))
            .lineLimit(1)
            .foregroundStyle(AppTheme.muted)
            .frame(height: 21)
            .help("Control Option Command 1 through 9 copies a favorite")
            .accessibilityLabel("Favorite shortcuts: Control Option Command 1 through 9")
    }

    private func favoriteRenameRow(_ favorite: FavoriteItem) -> some View {
        HStack(spacing: 11) {
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20)

            TextField("Favorite name", text: $favoriteRenameText)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.primary)
                .onSubmit {
                    finishRename(favorite.id)
                }

            Button("Done") {
                finishRename(favorite.id)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.accent)
        }
        .frame(height: 30)
        .help(favorite.value)
    }

    private func finishRename(_ favoriteID: UUID) {
        renameFavorite(favoriteID, favoriteRenameText)
        favoriteBeingRenamed = nil
    }
}
