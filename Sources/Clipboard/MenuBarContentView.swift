import SwiftUI

struct MenuBarContentView: View {
    let store: ClipboardStore
    let stateFilePath: String
    let copy: (String) -> Void
    let onHeightChange: (CGFloat) -> Void

    @State private var searchText = ""
    @State private var newSectionName = ""
    @State private var sectionBeingRenamed: UUID?
    @State private var favoriteBeingRenamed: UUID?
    @State private var renameText = ""
    @State private var favoriteRenameText = ""
    @State private var showingSettings = false
    @State private var showingAllHistory = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.surface.ignoresSafeArea()

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }

            if showingSettings {
                settingsView
            } else {
                mainView
            }
        }
        .frame(width: 330, height: preferredHeight)
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
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    searchField
                        .padding(.bottom, 14)

                    if !filteredFavorites.isEmpty {
                        favoritesSection
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

    private var preferredHeight: CGFloat {
        min(max(470, estimatedContentHeight), 680)
    }

    private var estimatedContentHeight: CGFloat {
        let favoritesHeight = filteredFavorites.isEmpty ? 0 : 31 + CGFloat(filteredFavorites.count) * 33
        let sectionsHeight = filteredSections.reduce(CGFloat(0)) { total, section in
            let visibleItems = section.collapsed && searchText.isEmpty ? 0 : filteredItems(section.items).count
            return total + 39 + CGFloat(visibleItems) * 33
        }
        let addSectionHeight = CGFloat(filteredSections.isEmpty ? 34 : 42)
        let historyRows = CGFloat(filteredHistory.count)
        let historyToggleHeight = shouldShowHistoryToggle ? CGFloat(26) : 0
        let historyHeight = 31 + historyRows * 33 + historyToggleHeight
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

    private var header: some View {
        HStack(alignment: .center) {
            Text("Clipboard")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.secondary)

            Spacer()

            Button("Settings", systemImage: "gearshape") {
                showingSettings = true
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.secondary)
            .help("Settings")
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.secondary)
                .frame(width: 20)

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .foregroundStyle(AppTheme.primary)
        }
        .frame(height: 30)
    }

    private var addSectionBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.square")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20)

            TextField("Add section", text: $newSectionName)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.primary)
                .onSubmit(createSection)

            Button("Add Section", systemImage: "plus", action: createSection)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.secondary)
                .help("Add Section")
        }
        .frame(height: 30)
    }

    private var favoritesSection: some View {
        SectionBlock(
            title: "Favorites",
            collapsed: false,
            onToggle: nil,
            trailingMenu: {
                favoriteShortcutHint
            }
        ) {
            ForEach(filteredFavorites) { favorite in
                if favoriteBeingRenamed == favorite.id {
                    favoriteRenameRow(favorite)
                } else {
                    FavoriteRow(
                        favorite: favorite,
                        copy: copy,
                        remove: { store.deleteFavorite(favorite.id) },
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

    private func userSection(_ section: ClipboardSection) -> some View {
        SectionBlock(
            title: section.name,
            collapsed: section.collapsed && searchText.isEmpty,
            onToggle: { store.toggleSection(section.id) },
            trailingMenu: {
                Menu {
                    Button("Rename") {
                        sectionBeingRenamed = section.id
                        renameText = section.name
                    }
                    Button("Delete", role: .destructive) {
                        store.deleteSection(section.id)
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
                    renameRow(section)
                }

                ForEach(filteredItems(section.items)) { item in
                    ClipboardRow(
                        icon: "text.quote",
                        value: item.value,
                        isFavorite: store.isFavorite(item.value),
                        copy: copy,
                        delete: { store.deleteSectionItem(item.id, in: section.id) },
                        toggleFavorite: { store.toggleFavorite(item.value) }
                    )
                    .draggable(ClipboardDragPayload(itemID: item.id, source: .section, sectionID: section.id))
                }
            }
        )
        .dropDestination(for: ClipboardDragPayload.self) { payloads, _ in
            guard let payload = payloads.first else { return false }

            switch payload.source {
            case .history:
                store.moveHistoryItem(payload.itemID, toSection: section.id)
            case .section:
                guard let sourceSectionID = payload.sectionID else { return false }
                store.moveSectionItem(payload.itemID, from: sourceSectionID, to: section.id)
            }

            return true
        }
    }

    private var historySection: some View {
        SectionBlock(title: "History", collapsed: false, onToggle: nil) {
            if filteredHistory.isEmpty {
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
            } else {
                ForEach(filteredHistory) { item in
                    ClipboardRow(
                        value: item.value,
                        isFavorite: store.isFavorite(item.value),
                        copy: copy,
                        delete: { store.deleteHistoryItem(item.id) },
                        toggleFavorite: { store.toggleFavorite(item.value) }
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

    private func renameRow(_ section: ClipboardSection) -> some View {
        HStack(spacing: 11) {
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20)

            TextField("Section name", text: $renameText)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.primary)
                .onSubmit {
                    finishRename(section.id)
                }

            Button("Done") {
                finishRename(section.id)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.accent)
        }
        .frame(height: 30)
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
                    finishFavoriteRename(favorite.id)
                }

            Button("Done") {
                finishFavoriteRename(favorite.id)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.accent)
        }
        .frame(height: 30)
        .help(favorite.value)
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

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button("Back", systemImage: "chevron.left") {
                    showingSettings = false
                    searchFocused = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.secondary)

                Text("Settings")
                    .font(.headline)
                    .foregroundStyle(AppTheme.secondary)

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 30)
            .padding(.bottom, 30)

            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("FILE PATH")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(AppTheme.muted)

                    Text(stateFilePath)
                        .font(.caption)
                        .foregroundStyle(AppTheme.primary)
                        .textSelection(.enabled)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text("THEME")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(AppTheme.muted)

                    HStack(spacing: 11) {
                        Image(systemName: "moon")
                            .font(.callout)
                            .frame(width: 20)
                        Text("Dark")
                    }
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .padding(.horizontal, 34)

            Spacer()
        }
        .padding(.horizontal, 10)
    }

    private var filteredFavorites: [FavoriteItem] {
        store.state.favorites.filter { matches($0.value) || matches($0.displayName) }
    }

    private var filteredSections: [ClipboardSection] {
        if searchText.isEmpty {
            return store.state.sections
        }

        return store.state.sections.compactMap { section in
            let items = filteredItems(section.items)
            if section.name.localizedStandardContains(searchText) || !items.isEmpty {
                var copy = section
                copy.items = items
                copy.collapsed = false
                return copy
            }
            return nil
        }
    }

    private var filteredHistory: [ClipboardItem] {
        let items = filteredItems(store.state.history)
        return showingAllHistory ? items : Array(items.prefix(5))
    }

    private var shouldShowHistoryToggle: Bool {
        filteredItems(store.state.history).count > 5
    }

    private func filteredItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        items.filter { matches($0.value) }
    }

    private func matches(_ value: String) -> Bool {
        searchText.isEmpty || value.localizedStandardContains(searchText)
    }

    private func createSection() {
        store.createSection(named: newSectionName)
        newSectionName = ""
    }

    private func finishRename(_ sectionID: UUID) {
        store.renameSection(sectionID, to: renameText)
        sectionBeingRenamed = nil
    }

    private func finishFavoriteRename(_ favoriteID: UUID) {
        store.renameFavorite(favoriteID, to: favoriteRenameText)
        favoriteBeingRenamed = nil
    }
}
