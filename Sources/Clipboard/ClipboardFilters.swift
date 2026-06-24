import Foundation

struct ClipboardFilters {
    let filteredFavorites: [FavoriteItem]
    let filteredSections: [ClipboardSection]
    let filteredHistory: [ClipboardItem]
    let shouldShowHistoryToggle: Bool

    init(state: ClipboardState, searchText: String, showingAllHistory: Bool) {
        filteredFavorites = state.favorites.filter {
            Self.matches($0.value, searchText: searchText) || Self.matches($0.displayName, searchText: searchText)
        }

        if searchText.isEmpty {
            filteredSections = state.sections
        } else {
            filteredSections = state.sections.compactMap { section in
                let items = Self.filteredItems(section.items, searchText: searchText)
                guard section.name.localizedStandardContains(searchText) || !items.isEmpty else {
                    return nil
                }

                var copy = section
                copy.items = items
                copy.collapsed = false
                return copy
            }
        }

        let favoriteValues = Set(state.favorites.map(\.value))
        let historyItems = Self.filteredItems(
            state.history.filter { !favoriteValues.contains($0.value) },
            searchText: searchText
        ).sorted {
            if $0.lastUsedAt == $1.lastUsedAt {
                return $0.createdAt > $1.createdAt
            }
            return $0.lastUsedAt > $1.lastUsedAt
        }
        filteredHistory = showingAllHistory ? historyItems : Array(historyItems.prefix(5))
        shouldShowHistoryToggle = historyItems.count > 5
    }

    private static func filteredItems(_ items: [ClipboardItem], searchText: String) -> [ClipboardItem] {
        items.filter {
            matches($0.value, searchText: searchText) || matches($0.displayName, searchText: searchText)
        }
    }

    private static func matches(_ value: String, searchText: String) -> Bool {
        searchText.isEmpty || value.localizedStandardContains(searchText)
    }
}
