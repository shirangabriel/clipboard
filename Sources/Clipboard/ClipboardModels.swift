import Foundation

struct ClipboardState: Codable, Equatable {
    var version: Int = 1
    var settings = ClipboardSettings()
    var favorites: [FavoriteItem] = []
    var sections: [ClipboardSection] = []
    var history: [ClipboardItem] = []
}

struct ClipboardSettings: Codable, Equatable {
    var historyLimit: Int = 20
}

struct ClipboardSection: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var collapsed: Bool = false
    var items: [ClipboardItem] = []
}

struct ClipboardItem: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var value: String
    var createdAt: Date = Date()
}

struct FavoriteItem: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var slot: Int
    var value: String
    var name: String?
    var createdAt: Date = Date()

    var displayName: String {
        guard let name, !name.isEmpty else { return value }
        return name
    }
}

extension String {
    var menuPreview: String {
        let singleLine = replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard singleLine.count > 80 else { return singleLine }
        let end = singleLine.index(singleLine.startIndex, offsetBy: 77)
        return String(singleLine[..<end]) + "..."
    }
}
