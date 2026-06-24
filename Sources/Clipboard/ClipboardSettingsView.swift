import SwiftUI

struct ClipboardSettingsView: View {
    let store: ClipboardStore
    let updater: AppUpdater

    var body: some View {
        Form {
            Section("Storage") {
                LabeledContent("File path") {
                    Text(store.stateURL.path)
                        .textSelection(.enabled)
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: appearanceBinding) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Updates") {
                Toggle("Automatically check for updates", isOn: automaticUpdateChecksBinding)

                Button("Check Now") {
                    updater.checkForUpdates()
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 440)
        .preferredColorScheme(store.state.settings.appearance.colorScheme)
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding(
            get: { store.state.settings.appearance },
            set: { store.setAppearance($0) }
        )
    }

    private var automaticUpdateChecksBinding: Binding<Bool> {
        Binding(
            get: { updater.automaticallyChecksForUpdates },
            set: { updater.automaticallyChecksForUpdates = $0 }
        )
    }
}
