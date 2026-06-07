import AppKit
import SwiftUI

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = ClipboardStore()
    private let pasteboard = PasteboardService()
    private var hotKeys: HotKeyService?
    private var statusItem: NSStatusItem?
    private var copyFeedbackTask: Task<Void, Never>?
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        configureStatusItem()
        configurePopover()

        pasteboard.start { [weak store] value in
            store?.addHistoryValue(value)
        }

        hotKeys = HotKeyService { [weak self] action in
            self?.handleHotKey(action)
        }
        hotKeys?.register()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        configureClipboardStatusIcon(on: item)
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        statusItem = item
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 330, height: 470)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(
                store: store,
                stateFilePath: store.stateURL.path,
                copy: { [weak self] value in
                    self?.copyValue(value)
                },
                onHeightChange: { [weak self] height in
                    self?.popover.contentSize = NSSize(width: 330, height: height)
                }
            )
        )
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func copyValue(_ value: String) {
        pasteboard.copy(value)
        showCopiedStatus()
        popover.performClose(nil)
    }

    private func showCopiedStatus() {
        copyFeedbackTask?.cancel()
        statusItem?.length = NSStatusItem.variableLength
        statusItem?.button?.image = nil
        statusItem?.button?.title = "Copied!"

        copyFeedbackTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled, let statusItem else { return }
            configureClipboardStatusIcon(on: statusItem)
            copyFeedbackTask = nil
        }
    }

    private func configureClipboardStatusIcon(on item: NSStatusItem) {
        item.length = NSStatusItem.squareLength
        item.button?.title = ""
        item.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
    }

    private func handleHotKey(_ action: HotKeyService.HotKeyAction) {
        switch action {
        case .openPopover:
            showPopover()
        case .copyFavorite(let slot):
            guard let value = store.favoriteValue(for: slot) else { return }
            copyValue(value)
        }
    }
}
