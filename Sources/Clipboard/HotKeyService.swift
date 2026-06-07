import Carbon
import Foundation

final class HotKeyService: @unchecked Sendable {
    enum HotKeyAction {
        case openPopover
        case copyFavorite(Int)
    }

    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var handler: EventHandlerRef?
    private let onAction: @MainActor (HotKeyAction) -> Void

    init(onAction: @escaping @MainActor (HotKeyAction) -> Void) {
        self.onAction = onAction
    }

    deinit {
        for ref in hotKeyRefs {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        if let handler {
            RemoveEventHandler(handler)
        }
    }

    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
                service.handle(id: hotKeyID.id)
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &handler
        )

        registerHotKey(id: 100, keyCode: UInt32(kVK_ANSI_V), modifiers: cmdKey | shiftKey)

        for slot in 1...9 {
            registerHotKey(
                id: UInt32(slot),
                keyCode: keyCode(forDigit: slot),
                modifiers: cmdKey | optionKey | controlKey
            )
        }
    }

    private func registerHotKey(id: UInt32, keyCode: UInt32, modifiers: Int) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C4950), id: id)

        RegisterEventHotKey(
            keyCode,
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        hotKeyRefs.append(hotKeyRef)
    }

    private func handle(id: UInt32) {
        let onAction = onAction
        Task { @MainActor in
            if id == 100 {
                onAction(.openPopover)
            } else if (1...9).contains(Int(id)) {
                onAction(.copyFavorite(Int(id)))
            }
        }
    }

    private func keyCode(forDigit digit: Int) -> UInt32 {
        switch digit {
        case 1: return UInt32(kVK_ANSI_1)
        case 2: return UInt32(kVK_ANSI_2)
        case 3: return UInt32(kVK_ANSI_3)
        case 4: return UInt32(kVK_ANSI_4)
        case 5: return UInt32(kVK_ANSI_5)
        case 6: return UInt32(kVK_ANSI_6)
        case 7: return UInt32(kVK_ANSI_7)
        case 8: return UInt32(kVK_ANSI_8)
        case 9: return UInt32(kVK_ANSI_9)
        default: return UInt32(kVK_ANSI_1)
        }
    }
}
