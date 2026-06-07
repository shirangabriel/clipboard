import AppKit
import Foundation

@MainActor
final class PasteboardService {
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var timer: Timer?
    private var isWritingProgrammatically = false

    init() {
        self.changeCount = pasteboard.changeCount
    }

    func start(onTextChange: @escaping @MainActor (String) -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll(onTextChange: onTextChange)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func copy(_ value: String) {
        isWritingProgrammatically = true
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        changeCount = pasteboard.changeCount
        isWritingProgrammatically = false
    }

    private func poll(onTextChange: @escaping @MainActor (String) -> Void) {
        guard pasteboard.changeCount != changeCount else { return }
        changeCount = pasteboard.changeCount

        guard !isWritingProgrammatically, let value = pasteboard.string(forType: .string) else {
            return
        }

        onTextChange(value)
    }
}
