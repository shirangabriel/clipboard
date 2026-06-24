import SwiftUI

struct HistorySectionView: View {
    let history: [ClipboardItem]
    let historyCollapsed: Bool
    let shouldShowHistoryToggle: Bool
    @Binding var showingAllHistory: Bool
    let toggleHistoryCollapsed: () -> Void
    let copyHistoryItem: (ClipboardItem) -> Void
    let deleteHistoryItem: (UUID) -> Void
    let isFavorite: (String) -> Bool
    let favoriteHistoryItem: (UUID) -> Void
    let renameHistoryItem: (UUID, String) -> Void
    let editHistoryItem: (UUID, String) -> Void

    var body: some View {
        SectionBlock(
            title: "History",
            collapsed: historyCollapsed,
            onToggle: toggleHistoryCollapsed
        ) {
            if history.isEmpty {
                emptyHistoryHint
            } else {
                ForEach(history) { item in
                    ClipboardRow(
                        item: item,
                        isFavorite: isFavorite(item.value),
                        copy: { _ in copyHistoryItem(item) },
                        delete: { deleteHistoryItem(item.id) },
                        toggleFavorite: { favoriteHistoryItem(item.id) },
                        rename: { renameHistoryItem(item.id, $0) },
                        edit: { editHistoryItem(item.id, $0) }
                    )
                    .draggable(ClipboardDragPayload(itemID: item.id, source: .history, sectionID: nil))
                }

                if shouldShowHistoryToggle {
                    Button(showingAllHistory ? "Show Less" : "Show All") {
                        showingAllHistory.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var emptyHistoryHint: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.secondary)
                .frame(width: 20)
            Text("No copied text yet")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(height: 30)
    }
}
