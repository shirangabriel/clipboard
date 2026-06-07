import SwiftUI

struct MenuBarSettingsView: View {
    let stateFilePath: String
    @Binding var appearance: AppAppearance
    let goBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button("Back", systemImage: "chevron.left", action: goBack)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.secondary)

                Text("Settings")
                    .font(.headline)
                    .foregroundStyle(AppTheme.secondary)

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 30)
            .padding(.bottom, 30)

            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("FILE PATH")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(AppTheme.muted)

                    Text(stateFilePath)
                        .font(.caption)
                        .foregroundStyle(AppTheme.primary)
                        .textSelection(.enabled)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text("THEME")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(AppTheme.muted)

                    Picker("Theme", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Label(appearance.title, systemImage: appearance.icon)
                                .tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 34)

            Spacer()
        }
        .padding(.horizontal, 10)
    }
}
