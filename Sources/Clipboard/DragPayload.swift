import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ClipboardDragPayload: Codable, Transferable {
    enum Source: String, Codable {
        case history
        case section
    }

    var itemID: UUID
    var source: Source
    var sectionID: UUID?

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}
