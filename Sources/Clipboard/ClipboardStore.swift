import Foundation
import Observation

@MainActor
@Observable
final class ClipboardStore {
    private(set) var state: ClipboardState

    let stateURL: URL
    private let backupURL: URL

    init() {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Clipboard", isDirectory: true)
        self.stateURL = supportURL.appendingPathComponent("clipboard.json")
        self.backupURL = supportURL.appendingPathComponent("clipboard.json.bak")
        self.state = Self.loadState(from: stateURL, backupURL: backupURL)
    }

    init(stateURL: URL, backupURL: URL, initialState: ClipboardState? = nil) {
        self.stateURL = stateURL
        self.backupURL = backupURL
        self.state = initialState ?? Self.loadState(from: stateURL, backupURL: backupURL)
    }

    // MARK: - History

    func addHistoryValue(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        state.history.removeAll { $0.value == value }
        state.history.insert(ClipboardItem(value: value), at: 0)
        if state.history.count > state.settings.historyLimit {
            state.history = Array(state.history.prefix(state.settings.historyLimit))
        }
        save()
    }

    func markHistoryItemUsed(_ itemID: UUID) {
        guard let index = state.history.firstIndex(where: { $0.id == itemID }) else { return }

        state.history[index].lastUsedAt = .now
        sortHistoryByRecentUse()
        save()
    }

    func renameHistoryItem(_ itemID: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = state.history.firstIndex(where: { $0.id == itemID }) else { return }

        state.history[index].name = trimmed.isEmpty ? nil : trimmed
        save()
    }

    func editHistoryItem(_ itemID: UUID, to value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = state.history.firstIndex(where: { $0.id == itemID })
        else {
            return
        }

        let oldValue = state.history[index].value
        state.history[index].value = value
        state.history[index].lastUsedAt = .now
        state.history.removeAll { $0.id != itemID && $0.value == value }
        updateFavorites(matching: oldValue, to: value)
        sortHistoryByRecentUse()
        save()
    }

    func deleteHistoryItem(_ itemID: UUID) {
        state.history.removeAll { $0.id == itemID }
        save()
    }

    // MARK: - Sections

    func createSection(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        state.sections.append(ClipboardSection(name: trimmed))
        save()
    }

    func renameSection(_ sectionID: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = state.sections.firstIndex(where: { $0.id == sectionID }) else { return }

        state.sections[index].name = trimmed
        save()
    }

    func deleteSection(_ sectionID: UUID) {
        state.sections.removeAll { $0.id == sectionID }
        save()
    }

    func toggleSection(_ sectionID: UUID) {
        guard let index = state.sections.firstIndex(where: { $0.id == sectionID }) else { return }
        state.sections[index].collapsed.toggle()
        save()
    }

    func deleteSectionItem(_ itemID: UUID, in sectionID: UUID) {
        guard let sectionIndex = state.sections.firstIndex(where: { $0.id == sectionID }) else { return }
        state.sections[sectionIndex].items.removeAll { $0.id == itemID }
        save()
    }

    func renameSectionItem(_ itemID: UUID, in sectionID: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let sectionIndex = state.sections.firstIndex(where: { $0.id == sectionID }),
            let itemIndex = state.sections[sectionIndex].items.firstIndex(where: { $0.id == itemID })
        else {
            return
        }

        state.sections[sectionIndex].items[itemIndex].name = trimmed.isEmpty ? nil : trimmed
        save()
    }

    func editSectionItem(_ itemID: UUID, in sectionID: UUID, to value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let sectionIndex = state.sections.firstIndex(where: { $0.id == sectionID }),
              let itemIndex = state.sections[sectionIndex].items.firstIndex(where: { $0.id == itemID })
        else {
            return
        }

        let oldValue = state.sections[sectionIndex].items[itemIndex].value
        state.sections[sectionIndex].items[itemIndex].value = value
        updateFavorites(matching: oldValue, to: value)
        save()
    }

    func moveHistoryItem(_ itemID: UUID, toSection sectionID: UUID) {
        guard
            let historyIndex = state.history.firstIndex(where: { $0.id == itemID }),
            let sectionIndex = state.sections.firstIndex(where: { $0.id == sectionID })
        else { return }

        let item = state.history.remove(at: historyIndex)
        state.sections[sectionIndex].items.append(item)
        save()
    }

    func moveSectionItem(_ itemID: UUID, from sourceSectionID: UUID, to targetSectionID: UUID) {
        guard
            let sourceIndex = state.sections.firstIndex(where: { $0.id == sourceSectionID }),
            let itemIndex = state.sections[sourceIndex].items.firstIndex(where: { $0.id == itemID }),
            let targetIndex = state.sections.firstIndex(where: { $0.id == targetSectionID })
        else { return }

        let item = state.sections[sourceIndex].items.remove(at: itemIndex)
        state.sections[targetIndex].items.append(item)
        save()
    }

    // MARK: - Favorites

    func favorite(_ value: String, name: String? = nil) {
        guard !state.favorites.contains(where: { $0.value == value }),
              let slot = firstAvailableFavoriteSlot()
        else {
            return
        }

        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        state.favorites.append(FavoriteItem(slot: slot, value: value, name: trimmedName?.isEmpty == false ? trimmedName : nil))
        state.favorites.sort { $0.slot < $1.slot }
        save()
    }

    func favoriteHistoryItem(_ itemID: UUID) {
        guard let index = state.history.firstIndex(where: { $0.id == itemID }) else { return }
        let item = state.history[index]
        guard addFavoriteWithoutSaving(value: item.value, name: item.name) else { return }

        state.history.remove(at: index)
        save()
    }

    func favoriteSectionItem(_ itemID: UUID, in sectionID: UUID) {
        guard
            let sectionIndex = state.sections.firstIndex(where: { $0.id == sectionID }),
            let item = state.sections[sectionIndex].items.first(where: { $0.id == itemID })
        else {
            return
        }

        guard addFavoriteWithoutSaving(value: item.value, name: item.name) else { return }

        save()
    }

    func toggleFavorite(_ value: String) {
        if let favorite = state.favorites.first(where: { $0.value == value }) {
            deleteFavorite(favorite.id)
        } else {
            favorite(value)
        }
    }

    func isFavorite(_ value: String) -> Bool {
        state.favorites.contains { $0.value == value }
    }

    func renameFavorite(_ favoriteID: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = state.favorites.firstIndex(where: { $0.id == favoriteID }) else { return }

        state.favorites[index].name = trimmed.isEmpty ? nil : trimmed
        save()
    }

    func deleteFavorite(_ favoriteID: UUID) {
        guard let index = state.favorites.firstIndex(where: { $0.id == favoriteID }) else { return }

        let favorite = state.favorites.remove(at: index)
        restoreFavoriteToHistory(favorite)
        save()
    }

    func favoriteValue(for slot: Int) -> String? {
        state.favorites.first(where: { $0.slot == slot })?.value
    }

    private func firstAvailableFavoriteSlot() -> Int? {
        let usedSlots = Set(state.favorites.map(\.slot))
        return (1...9).first { !usedSlots.contains($0) }
    }

    @discardableResult
    private func addFavoriteWithoutSaving(value: String, name: String?) -> Bool {
        guard !state.favorites.contains(where: { $0.value == value }),
              let slot = firstAvailableFavoriteSlot()
        else {
            return false
        }

        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        state.favorites.append(FavoriteItem(slot: slot, value: value, name: trimmedName?.isEmpty == false ? trimmedName : nil))
        state.favorites.sort { $0.slot < $1.slot }
        return true
    }

    private func restoreFavoriteToHistory(_ favorite: FavoriteItem) {
        state.history.removeAll { $0.value == favorite.value }
        state.history.insert(ClipboardItem(value: favorite.value, name: favorite.name), at: 0)
        if state.history.count > state.settings.historyLimit {
            state.history = Array(state.history.prefix(state.settings.historyLimit))
        }
    }

    private func updateFavorites(matching oldValue: String, to newValue: String) {
        guard oldValue != newValue else { return }

        if state.favorites.contains(where: { $0.value == newValue }) {
            state.favorites.removeAll { $0.value == oldValue }
            return
        }

        for index in state.favorites.indices where state.favorites[index].value == oldValue {
            state.favorites[index].value = newValue
        }
    }

    private func sortHistoryByRecentUse() {
        state.history.sort {
            if $0.lastUsedAt == $1.lastUsedAt {
                return $0.createdAt > $1.createdAt
            }
            return $0.lastUsedAt > $1.lastUsedAt
        }
    }

    // MARK: - Settings

    func setAppearance(_ appearance: AppAppearance) {
        guard state.settings.appearance != appearance else { return }
        state.settings.appearance = appearance
        save()
    }

    func toggleHistoryCollapsed() {
        state.settings.historyCollapsed.toggle()
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            try FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)

            if FileManager.default.fileExists(atPath: stateURL.path) {
                try? FileManager.default.removeItem(at: backupURL)
                try? FileManager.default.copyItem(at: stateURL, to: backupURL)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(state)

            let temporaryURL = stateURL.deletingLastPathComponent()
                .appendingPathComponent(".clipboard.json.tmp")
            try data.write(to: temporaryURL, options: .atomic)

            if FileManager.default.fileExists(atPath: stateURL.path) {
                try FileManager.default.removeItem(at: stateURL)
            }
            try FileManager.default.moveItem(at: temporaryURL, to: stateURL)
        } catch {
            assertionFailure("Failed to save clipboard state: \(error)")
        }
    }

    private static func loadState(from url: URL, backupURL: URL) -> ClipboardState {
        if let state = decodeState(from: url) {
            return state
        }

        if let backup = decodeState(from: backupURL) {
            return backup
        }

        return ClipboardState()
    }

    private static func decodeState(from url: URL) -> ClipboardState? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ClipboardState.self, from: data)
    }
}
