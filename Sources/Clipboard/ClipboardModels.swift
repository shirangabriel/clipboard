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
    var appearance: AppAppearance = .system
    var historyCollapsed: Bool = false

    private enum CodingKeys: String, CodingKey {
        case historyLimit
        case appearance
        case historyCollapsed
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        historyLimit = try container.decodeIfPresent(Int.self, forKey: .historyLimit) ?? 20
        appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        historyCollapsed = try container.decodeIfPresent(Bool.self, forKey: .historyCollapsed) ?? false
    }
}

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system:
            "circle.lefthalf.filled"
        case .light:
            "sun.max"
        case .dark:
            "moon"
        }
    }
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
    var createdAt: Date = .now
}

struct FavoriteItem: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var slot: Int
    var value: String
    var name: String?
    var createdAt: Date = .now

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
