import SwiftUI

struct UserSectionView: View {
    let section: ClipboardSection
    @Binding var sectionBeingRenamed: UUID?
    @Binding var renameText: String
    let copy: (String) -> Void
    let toggleSection: (UUID) -> Void
    let renameSection: (UUID, String) -> Void
    let deleteSection: (UUID) -> Void
    let deleteItem: (UUID, UUID) -> Void
    let moveHistoryItem: (UUID, UUID) -> Void
    let moveSectionItem: (UUID, UUID, UUID) -> Void
    let isFavorite: (String) -> Bool
    let toggleFavorite: (String) -> Void

    var body: some View {
        SectionBlock(
            title: section.name,
            collapsed: section.collapsed,
            onToggle: { toggleSection(section.id) },
            trailingMenu: {
                Menu {
                    Button("Rename") {
                        sectionBeingRenamed = section.id
                        renameText = section.name
                    }
                    Button("Delete", role: .destructive) {
                        deleteSection(section.id)
                    }
                } label: {
                    Label("Section Options", systemImage: "ellipsis")
                }
                .labelStyle(.iconOnly)
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .foregroundStyle(AppTheme.secondary)
            },
            content: {
                if sectionBeingRenamed == section.id {
                    renameRow
                }

                if section.items.isEmpty {
                    emptySectionHint
                }

                ForEach(section.items) { item in
                    ClipboardRow(
                        value: item.value,
                        isFavorite: isFavorite(item.value),
                        copy: copy,
                        delete: { deleteItem(item.id, section.id) },
                        toggleFavorite: { toggleFavorite(item.value) }
                    )
                    .draggable(ClipboardDragPayload(itemID: item.id, source: .section, sectionID: section.id))
                }
            }
        )
        .dropDestination(for: ClipboardDragPayload.self) { payloads, _ in
            guard let payload = payloads.first else { return false }

            switch payload.source {
            case .history:
                moveHistoryItem(payload.itemID, section.id)
            case .section:
                guard let sourceSectionID = payload.sectionID else { return false }
                moveSectionItem(payload.itemID, sourceSectionID, section.id)
            }

            return true
        }
    }

    private var renameRow: some View {
        HStack(spacing: 11) {
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20)

            TextField("Section name", text: $renameText)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.primary)
                .onSubmit(finishRename)

            Button("Done", action: finishRename)
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
        }
        .frame(height: 30)
    }

    private var emptySectionHint: some View {
        Text("Drag items here to add them to this section.")
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(AppTheme.muted)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
            .padding(.leading, 2)
    }

    private func finishRename() {
        renameSection(section.id, renameText)
        sectionBeingRenamed = nil
    }
}
