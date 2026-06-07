import Foundation
import Testing
@testable import Clipboard

struct ClipboardModelsTests {
    @Test
    func favoriteDisplayNameFallsBackToValueWhenNameIsMissingOrEmpty() {
        #expect(FavoriteItem(slot: 1, value: "Raw value", name: nil).displayName == "Raw value")
        #expect(FavoriteItem(slot: 1, value: "Raw value", name: "").displayName == "Raw value")
        #expect(FavoriteItem(slot: 1, value: "Raw value", name: "Label").displayName == "Label")
    }

    @Test
    func menuPreviewTrimsWhitespaceAndReplacesTabsAndNewlines() {
        let value = " \nFirst\tSecond\nThird "

        #expect(value.menuPreview == "First Second Third")
    }

    @Test
    func menuPreviewTruncatesLongTextToEightyCharactersIncludingEllipsis() {
        let value = String(repeating: "A", count: 81)

        #expect(value.menuPreview.count == 80)
        #expect(value.menuPreview == String(repeating: "A", count: 77) + "...")
    }

    @Test
    func settingsDecodeMissingFieldsUsingDefaults() throws {
        let data = Data(#"{}"#.utf8)
        let settings = try JSONDecoder().decode(ClipboardSettings.self, from: data)

        #expect(settings.historyLimit == 20)
        #expect(settings.appearance == .system)
        #expect(settings.historyCollapsed == false)
    }
}
