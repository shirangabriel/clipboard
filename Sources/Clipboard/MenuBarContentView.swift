import SwiftUI

struct MenuBarContentView: View {
    let store: ClipboardStore
    let copy: (String) -> Void
    let openSettings: () -> Void
    let onHeightChange: (CGFloat) -> Void

    @State private var searchText = ""
    @State private var newSectionName = ""
    @State private var sectionBeingRenamed: UUID?
    @State private var favoriteBeingRenamed: UUID?
    @State private var renameText = ""
    @State private var favoriteRenameText = ""
    @State private var showingAllHistory = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        mainView
        .frame(width: 330, height: preferredHeight)
        .background(AppTheme.surface.ignoresSafeArea())
        .preferredColorScheme(store.state.settings.appearance.colorScheme)
        .font(.system(size: 13, weight: .regular))
        .foregroundStyle(AppTheme.primary)
        .onAppear {
            searchFocused = true
            onHeightChange(preferredHeight)
        }
        .onChange(of: preferredHeight) { _, newHeight in
            onHeightChange(newHeight)
        }
    }

    private var mainView: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuBarHeaderView(showSettings: openSettings)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    SearchFieldView(searchText: $searchText, searchFocused: $searchFocused)
                        .padding(.bottom, 14)

                    if !filteredFavorites.isEmpty {
                        FavoritesSectionView(
                            favorites: filteredFavorites,
                            favoriteBeingRenamed: $favoriteBeingRenamed,
                            favoriteRenameText: $favoriteRenameText,
                            copy: copy,
                            deleteFavorite: store.deleteFavorite,
                            renameFavorite: store.renameFavorite
                        )
                    }

                    if filteredSections.isEmpty {
                        sectionDividerIfNeeded(!filteredFavorites.isEmpty)
                        addSectionBar
                    } else {
                        ForEach(filteredSections) { section in
                            sectionDividerIfNeeded(true)
                            userSection(section)
                        }

                        addSectionBar
                            .padding(.top, 8)
                    }

                    sectionDividerIfNeeded(true)
                    historySection
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 24)
    }

    private var addSectionBar: some View {
        AddSectionRow(name: $newSectionName, create: createSection)
    }

    private func userSection(_ section: ClipboardSection) -> some View {
        UserSectionView(
            section: section,
            sectionBeingRenamed: $sectionBeingRenamed,
            renameText: $renameText,
            copy: copy,
            toggleSection: store.toggleSection,
            renameSection: store.renameSection,
            deleteSection: store.deleteSection,
            deleteItem: { itemID, sectionID in
                store.deleteSectionItem(itemID, in: sectionID)
            },
            moveHistoryItem: { itemID, sectionID in
                store.moveHistoryItem(itemID, toSection: sectionID)
            },
            moveSectionItem: { itemID, sourceSectionID, targetSectionID in
                store.moveSectionItem(itemID, from: sourceSectionID, to: targetSectionID)
            },
            isFavorite: store.isFavorite,
            toggleFavorite: store.toggleFavorite
        )
    }

    private var historySection: some View {
        HistorySectionView(
            history: filteredHistory,
            historyCollapsed: store.state.settings.historyCollapsed,
            shouldShowHistoryToggle: shouldShowHistoryToggle,
            showingAllHistory: $showingAllHistory,
            toggleHistoryCollapsed: store.toggleHistoryCollapsed,
            copy: copy,
            deleteHistoryItem: store.deleteHistoryItem,
            isFavorite: store.isFavorite,
            toggleFavorite: store.toggleFavorite
        )
    }

    private var preferredHeight: CGFloat {
        min(max(470, estimatedContentHeight), 680)
    }

    private var estimatedContentHeight: CGFloat {
        let favoritesHeight = filteredFavorites.isEmpty ? 0 : 31 + CGFloat(filteredFavorites.count) * 33
        let sectionsHeight = filteredSections.reduce(CGFloat(0)) { total, section in
            let visibleItems = section.collapsed && searchText.isEmpty ? 0 : section.items.count
            let emptyHintHeight = visibleItems == 0 && !(section.collapsed && searchText.isEmpty) ? CGFloat(30) : 0
            return total + 39 + CGFloat(visibleItems) * 33 + emptyHintHeight
        }
        let addSectionHeight = CGFloat(filteredSections.isEmpty ? 34 : 42)
        let historyRows = CGFloat(filteredHistory.count)
        let historyToggleHeight = shouldShowHistoryToggle ? CGFloat(26) : 0
        let historyHeight = store.state.settings.historyCollapsed ? CGFloat(21) : 31 + historyRows * 33 + historyToggleHeight
        let chromeHeight = CGFloat(112)
        let dividers = CGFloat(visibleDividerCount) * 21

        return chromeHeight + favoritesHeight + sectionsHeight + addSectionHeight + historyHeight + dividers
    }

    private var visibleDividerCount: Int {
        var count = filteredSections.count
        if filteredSections.isEmpty && !filteredFavorites.isEmpty {
            count += 1
        }
        count += 1
        return count
    }

    private var filters: ClipboardFilters {
        ClipboardFilters(state: store.state, searchText: searchText, showingAllHistory: showingAllHistory)
    }

    private var filteredFavorites: [FavoriteItem] {
        filters.filteredFavorites
    }

    private var filteredSections: [ClipboardSection] {
        filters.filteredSections
    }

    private var filteredHistory: [ClipboardItem] {
        filters.filteredHistory
    }

    private var shouldShowHistoryToggle: Bool {
        filters.shouldShowHistoryToggle
    }

    private func sectionDividerIfNeeded(_ visible: Bool) -> some View {
        Group {
            if visible {
                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)
                    .padding(.vertical, 10)
            }
        }
    }

    private func createSection() {
        store.createSection(named: newSectionName)
        newSectionName = ""
    }
}
