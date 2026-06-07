import SwiftUI

struct FavoriteRow: View {
    let favorite: FavoriteItem
    let copy: (String) -> Void
    let remove: () -> Void
    let rename: () -> Void

    @State private var isHovering = false
    @State private var isCopied = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                copyValue()
            } label: {
                rowLabel
            }
            .buttonStyle(.plain)
            .help(favorite.value)
            .accessibilityLabel("Copy favorite \(favorite.slot), shortcut Control Option Command \(favorite.slot)")
            .frame(maxWidth: .infinity)
            .contextMenu {
                Button("Copy", action: copyValue)
                Button("Rename", systemImage: "pencil", action: rename)
                Button("Remove Favorite", systemImage: "star.fill", role: .destructive, action: remove)
            }

            if isCopied {
                Label("Copied", systemImage: "checkmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28, height: 28)
                    .transition(.opacity)
                    .accessibilityLabel("Copied")
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

    private func copyValue() {
        copy(favorite.value)
        withAnimation(.easeOut(duration: 0.12)) {
            isCopied = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
}
