import SwiftUI

struct ClipboardRow: View {
    let icon: String?
    let item: ClipboardItem
    let isFavorite: Bool
    let copy: (String) -> Void
    let delete: () -> Void
    let toggleFavorite: () -> Void
    let rename: (String) -> Void
    let edit: (String) -> Void

    init(
        icon: String? = nil,
        item: ClipboardItem,
        isFavorite: Bool,
        copy: @escaping (String) -> Void,
        delete: @escaping () -> Void,
        toggleFavorite: @escaping () -> Void,
        rename: @escaping (String) -> Void,
        edit: @escaping (String) -> Void
    ) {
        self.icon = icon
        self.item = item
        self.isFavorite = isFavorite
        self.copy = copy
        self.delete = delete
        self.toggleFavorite = toggleFavorite
        self.rename = rename
        self.edit = edit
    }

    @State private var isHovering = false
    @State private var editMode: RowEditMode?
    @State private var draftText = ""

    var body: some View {
        Group {
            if let editMode {
                inlineEditRow(editMode)
            } else {
                displayRow
            }
        }
        .frame(height: rowHeight)
        .padding(.horizontal, 2)
        .background(isHovering ? AppTheme.hover : Color.clear)
        .clipShape(.rect(cornerRadius: 6))
        .onHover { isHovering = $0 }
    }

    private var displayRow: some View {
        HStack(spacing: 8) {
            Button {
                copy(item.value)
            } label: {
                rowLabel
            }
            .buttonStyle(.plain)
            .help(item.value)
            .accessibilityLabel("Copy \(item.displayName)")
            .frame(maxWidth: .infinity)
            .contextMenu {
                Button("Copy", action: { copy(item.value) })
                Button("Rename", systemImage: "pencil", action: startRename)
                Button("Edit", systemImage: "text.cursor", action: startEdit)
                Button(favoriteActionLabel, systemImage: favoriteIcon, action: toggleFavorite)
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            }

            IconButton(systemName: favoriteIcon, label: favoriteActionLabel, action: toggleFavorite)
            IconButton(systemName: "trash", label: "Delete", action: delete)
        }
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

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName.menuPreview)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if showsValueSubtitle {
                    Text(item.value.menuPreview)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppTheme.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
    }

    private func inlineEditRow(_ mode: RowEditMode) -> some View {
        HStack(spacing: 11) {
            Image(systemName: mode.icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20)
                .accessibilityHidden(true)

            TextField(mode.placeholder, text: $draftText, axis: mode.textFieldAxis)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.primary)
                .lineLimit(mode.lineLimit)
                .onSubmit(finishInlineEdit)

            Button("Done", action: finishInlineEdit)
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
        }
        .help(item.value)
    }

    private func startRename() {
        editMode = .rename
        draftText = item.name ?? ""
    }

    private func startEdit() {
        editMode = .value
        draftText = item.value
    }

    private func finishInlineEdit() {
        switch editMode {
        case .rename:
            rename(draftText)
        case .value:
            edit(draftText)
        case nil:
            break
        }

        editMode = nil
        draftText = ""
    }

    private var favoriteIcon: String {
        isFavorite ? "star.fill" : "star"
    }

    private var favoriteActionLabel: String {
        isFavorite ? "Remove Favorite" : "Add to Favorites"
    }

    private var rowHeight: CGFloat {
        if editMode == .value {
            return 78
        }

        return editMode == nil && showsValueSubtitle ? 46 : 30
    }

    private var showsValueSubtitle: Bool {
        guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty
        else {
            return false
        }

        return name != item.value
    }
}

private enum RowEditMode {
    case rename
    case value

    var icon: String {
        switch self {
        case .rename:
            "pencil"
        case .value:
            "text.cursor"
        }
    }

    var placeholder: String {
        switch self {
        case .rename:
            "Item name"
        case .value:
            "Clipboard value"
        }
    }

    var textFieldAxis: Axis {
        switch self {
        case .rename:
            .horizontal
        case .value:
            .vertical
        }
    }

    var lineLimit: ClosedRange<Int> {
        switch self {
        case .rename:
            1...1
        case .value:
            1...4
        }
    }
}
