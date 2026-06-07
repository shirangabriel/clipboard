import SwiftUI

struct IconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(label, systemImage: systemName, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.secondary)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            .help(label)
    }
}
