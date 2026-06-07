import Foundation
import Testing
@testable import Clipboard

@MainActor
struct ClipboardStoreTests {
    @Test
    func blankHistoryValuesAreIgnored() throws {
        let harness = try StoreHarness()
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)

        store.addHistoryValue(" \n\t ")

        #expect(store.state.history.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: harness.stateURL.path))
    }

    @Test
    func historyDeduplicatesValuesAndMovesLatestCopyToTop() throws {
        let harness = try StoreHarness()
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)

        store.addHistoryValue("A")
        store.addHistoryValue("B")
        store.addHistoryValue("A")

        #expect(store.state.history.map(\.value) == ["A", "B"])
    }

    @Test
    func historyRespectsLimit() throws {
        let harness = try StoreHarness()
        var state = ClipboardState()
        state.settings.historyLimit = 3
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL, initialState: state)

        for value in ["A", "B", "C", "D", "E"] {
            store.addHistoryValue(value)
        }

        #expect(store.state.history.map(\.value) == ["E", "D", "C"])
    }

    @Test
    func loadFallsBackToBackupWhenPrimaryStateIsInvalid() throws {
        let harness = try StoreHarness()
        try Data("not json".utf8).write(to: harness.stateURL)

        var backupState = ClipboardState()
        backupState.history = [ClipboardItem(value: "Recovered")]
        try harness.write(backupState, to: harness.backupURL)

        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)

        #expect(store.state.history.map(\.value) == ["Recovered"])
    }

    @Test
    func saveCreatesBackupOfPreviousState() throws {
        let harness = try StoreHarness()
        let firstState = ClipboardState(history: [ClipboardItem(value: "Before")])
        try harness.write(firstState, to: harness.stateURL)

        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)
        store.addHistoryValue("After")

        let backup = try harness.readState(from: harness.backupURL)
        #expect(backup.history.map(\.value) == ["Before"])
        #expect(store.state.history.map(\.value) == ["After", "Before"])
    }

    @Test
    func sectionCreateRenameDeleteAndToggle() throws {
        let harness = try StoreHarness()
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)

        store.createSection(named: " Work ")
        store.createSection(named: " ")
        let sectionID = try #require(store.state.sections.first?.id)

        #expect(store.state.sections.map(\.name) == ["Work"])

        store.renameSection(sectionID, to: " Ideas ")
        #expect(store.state.sections.first?.name == "Ideas")

        store.renameSection(sectionID, to: " ")
        #expect(store.state.sections.first?.name == "Ideas")

        store.toggleSection(sectionID)
        #expect(store.state.sections.first?.collapsed == true)

        store.deleteSection(sectionID)
        #expect(store.state.sections.isEmpty)
    }

    @Test
    func movingHistoryItemIntoSectionRemovesItFromHistory() throws {
        let harness = try StoreHarness()
        var state = ClipboardState()
        let item = ClipboardItem(value: "Move me")
        let section = ClipboardSection(name: "Work")
        state.history = [item]
        state.sections = [section]
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL, initialState: state)

        store.moveHistoryItem(item.id, toSection: section.id)

        #expect(store.state.history.isEmpty)
        #expect(store.state.sections.first?.items == [item])
    }

    @Test
    func movingSectionItemRemovesItFromSourceAndAppendsItToTarget() throws {
        let harness = try StoreHarness()
        var state = ClipboardState()
        let item = ClipboardItem(value: "Move me")
        let source = ClipboardSection(name: "Source", items: [item])
        let target = ClipboardSection(name: "Target")
        state.sections = [source, target]
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL, initialState: state)

        store.moveSectionItem(item.id, from: source.id, to: target.id)

        #expect(store.state.sections[0].items.isEmpty)
        #expect(store.state.sections[1].items == [item])
    }

    @Test
    func favoritesUseFirstAvailableSlot() throws {
        let harness = try StoreHarness()
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)

        store.favorite("One")
        store.favorite("Two")
        store.favorite("Three")
        let secondFavoriteID = try #require(store.state.favorites.first { $0.slot == 2 }?.id)
        store.deleteFavorite(secondFavoriteID)
        store.favorite("Replacement")

        #expect(store.state.favorites.first { $0.value == "Replacement" }?.slot == 2)
        #expect(store.state.favorites.map(\.slot) == [1, 2, 3])
    }

    @Test
    func duplicateFavoritesAreRejectedAndFavoritesCapAtNine() throws {
        let harness = try StoreHarness()
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)

        store.favorite("One")
        store.favorite("One")
        for index in 2...10 {
            store.favorite("Favorite \(index)")
        }

        #expect(store.state.favorites.count == 9)
        #expect(store.state.favorites.filter { $0.value == "One" }.count == 1)
        #expect(store.state.favorites.map(\.slot) == Array(1...9))
    }

    @Test
    func toggleFavoriteAddsThenRemovesValue() throws {
        let harness = try StoreHarness()
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)

        store.toggleFavorite("Pinned")
        #expect(store.isFavorite("Pinned"))

        store.toggleFavorite("Pinned")
        #expect(!store.isFavorite("Pinned"))
    }

    @Test
    func renameFavoriteTrimsNameAndClearsEmptyName() throws {
        let harness = try StoreHarness()
        let store = ClipboardStore(stateURL: harness.stateURL, backupURL: harness.backupURL)

        store.favorite("https://example.com")
        let favoriteID = try #require(store.state.favorites.first?.id)

        store.renameFavorite(favoriteID, to: " Docs ")
        #expect(store.state.favorites.first?.name == "Docs")
        #expect(store.state.favorites.first?.displayName == "Docs")

        store.renameFavorite(favoriteID, to: " ")
        #expect(store.state.favorites.first?.name == nil)
        #expect(store.state.favorites.first?.displayName == "https://example.com")
    }
}

struct StoreHarness {
    let directory: URL
    let stateURL: URL
    let backupURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipboardTests-\(UUID().uuidString)", isDirectory: true)
        stateURL = directory.appendingPathComponent("clipboard.json")
        backupURL = directory.appendingPathComponent("clipboard.json.bak")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func write(_ state: ClipboardState, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        try data.write(to: url)
    }

    func readState(from url: URL) throws -> ClipboardState {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ClipboardState.self, from: data)
    }
}
