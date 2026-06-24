import Foundation
import Testing
@testable import Clipboard

struct ClipboardFiltersTests {
    @Test
    func favoritesMatchByValueOrDisplayName() {
        var state = ClipboardState()
        state.favorites = [
            FavoriteItem(slot: 1, value: "API token", name: nil),
            FavoriteItem(slot: 2, value: "https://example.com", name: "Docs")
        ]

        let valueMatch = ClipboardFilters(state: state, searchText: "token", showingAllHistory: false)
        let nameMatch = ClipboardFilters(state: state, searchText: "docs", showingAllHistory: false)

        #expect(valueMatch.filteredFavorites.map(\.slot) == [1])
        #expect(nameMatch.filteredFavorites.map(\.slot) == [2])
    }

    @Test
    func sectionsMatchByNameOrContainedItem() {
        var state = ClipboardState()
        state.sections = [
            ClipboardSection(name: "Work", items: [ClipboardItem(value: "Sprint notes")]),
            ClipboardSection(name: "Personal", items: [ClipboardItem(value: "Shopping list")])
        ]

        let nameMatch = ClipboardFilters(state: state, searchText: "work", showingAllHistory: false)
        let itemMatch = ClipboardFilters(state: state, searchText: "shopping", showingAllHistory: false)

        #expect(nameMatch.filteredSections.map(\.name) == ["Work"])
        #expect(itemMatch.filteredSections.map(\.name) == ["Personal"])
    }

    @Test
    func searchReturnsOnlyMatchingSectionItems() {
        var state = ClipboardState()
        state.sections = [
            ClipboardSection(
                name: "Work",
                items: [
                    ClipboardItem(value: "Sprint notes"),
                    ClipboardItem(value: "Release checklist")
                ]
            )
        ]

        let filters = ClipboardFilters(state: state, searchText: "release", showingAllHistory: false)

        #expect(filters.filteredSections.first?.items.map(\.value) == ["Release checklist"])
    }

    @Test
    func itemNamesAreSearchableInHistoryAndSections() {
        var state = ClipboardState()
        state.history = [
            ClipboardItem(value: "brew reinstall --cask shirangabriel/tap/clipboard", name: "Install Clipboard")
        ]
        state.sections = [
            ClipboardSection(name: "Commands", items: [
                ClipboardItem(value: "swift test", name: "Run tests")
            ])
        ]

        let historyMatch = ClipboardFilters(state: state, searchText: "install", showingAllHistory: false)
        let sectionMatch = ClipboardFilters(state: state, searchText: "tests", showingAllHistory: false)

        #expect(historyMatch.filteredHistory.map(\.value) == ["brew reinstall --cask shirangabriel/tap/clipboard"])
        #expect(sectionMatch.filteredSections.first?.items.map(\.value) == ["swift test"])
    }

    @Test
    func collapsedSectionsAreExpandedInSearchResults() {
        var state = ClipboardState()
        state.sections = [
            ClipboardSection(
                name: "Work",
                collapsed: true,
                items: [ClipboardItem(value: "Release checklist")]
            )
        ]

        let filters = ClipboardFilters(state: state, searchText: "release", showingAllHistory: false)

        #expect(filters.filteredSections.first?.collapsed == false)
    }

    @Test
    func historyShowsFirstFiveUnlessShowingAll() {
        var state = ClipboardState()
        state.history = (1...7).map {
            ClipboardItem(
                value: "Item \($0)",
                createdAt: Date(timeIntervalSince1970: TimeInterval(100 - $0)),
                lastUsedAt: Date(timeIntervalSince1970: TimeInterval(100 - $0))
            )
        }

        let limited = ClipboardFilters(state: state, searchText: "", showingAllHistory: false)
        let full = ClipboardFilters(state: state, searchText: "", showingAllHistory: true)

        #expect(limited.filteredHistory.map(\.value) == ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"])
        #expect(full.filteredHistory.map(\.value) == state.history.map(\.value))
    }

    @Test
    func historyToggleAppearsOnlyWhenFilteredHistoryHasMoreThanFiveItems() {
        var state = ClipboardState()
        state.history = [
            ClipboardItem(value: "Apple 1", lastUsedAt: Date(timeIntervalSince1970: 7)),
            ClipboardItem(value: "Apple 2", lastUsedAt: Date(timeIntervalSince1970: 6)),
            ClipboardItem(value: "Apple 3", lastUsedAt: Date(timeIntervalSince1970: 5)),
            ClipboardItem(value: "Apple 4", lastUsedAt: Date(timeIntervalSince1970: 4)),
            ClipboardItem(value: "Apple 5", lastUsedAt: Date(timeIntervalSince1970: 3)),
            ClipboardItem(value: "Apple 6", lastUsedAt: Date(timeIntervalSince1970: 2)),
            ClipboardItem(value: "Banana", lastUsedAt: Date(timeIntervalSince1970: 1))
        ]

        let manyMatches = ClipboardFilters(state: state, searchText: "apple", showingAllHistory: false)
        let fewMatches = ClipboardFilters(state: state, searchText: "banana", showingAllHistory: false)

        #expect(manyMatches.shouldShowHistoryToggle)
        #expect(!fewMatches.shouldShowHistoryToggle)
    }
}
