import AppKit
import SwiftUI

enum AppTheme {
    static let surface = adaptiveColor(
        light: NSColor(calibratedWhite: 0.96, alpha: 1),
        dark: NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.15, alpha: 1)
    )
    static let hover = adaptiveColor(
        light: NSColor(calibratedWhite: 0, alpha: 0.06),
        dark: NSColor(calibratedWhite: 1, alpha: 0.06)
    )
    static let divider = adaptiveColor(
        light: NSColor(calibratedWhite: 0, alpha: 0.12),
        dark: NSColor(calibratedWhite: 1, alpha: 0.10)
    )
    static let primary = adaptiveColor(
        light: NSColor(calibratedWhite: 0.10, alpha: 0.94),
        dark: NSColor(calibratedWhite: 1, alpha: 0.92)
    )
    static let secondary = adaptiveColor(
        light: NSColor(calibratedWhite: 0.24, alpha: 0.72),
        dark: NSColor(calibratedWhite: 1, alpha: 0.62)
    )
    static let muted = adaptiveColor(
        light: NSColor(calibratedWhite: 0.34, alpha: 0.62),
        dark: NSColor(calibratedWhite: 1, alpha: 0.48)
    )
    static let accent = Color(red: 0.50, green: 0.68, blue: 1)

    private static func adaptiveColor(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua])
            return match == .darkAqua ? dark : light
        })
    }
}

extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
