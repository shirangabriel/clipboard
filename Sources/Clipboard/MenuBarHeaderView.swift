import SwiftUI

struct MenuBarHeaderView: View {
    let showSettings: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text("Clipboard")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.secondary)

            Spacer()

            Button("Settings", systemImage: "gearshape", action: showSettings)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.secondary)
                .help("Settings")
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 12)
    }
}
