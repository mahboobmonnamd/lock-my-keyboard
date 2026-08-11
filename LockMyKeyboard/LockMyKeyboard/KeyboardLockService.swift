import CoreGraphics
import Foundation

enum KeyboardLockError: Error {
    case tapCreateFailed
}

/// Session-level CGEvent tap that swallows keyboard events while active.
final class KeyboardLockService: @unchecked Sendable {
    private let tapBox = TapBox()
    private var runLoopSource: CFRunLoopSource?

    var isActive: Bool { tapBox.eventTap != nil }

    func start() throws {
        stop()

        let mask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let refcon {
                    let box = Unmanaged<TapBox>.fromOpaque(refcon).takeUnretainedValue()
                    if let tap = box.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                }
                return Unmanaged.passUnretained(event)
            }
            return nil
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(tapBox).toOpaque()
        ) else {
            throw KeyboardLockError.tapCreateFailed
        }

        tapBox.eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = tapBox.eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            tapBox.eventTap = nil
        }
    }

    deinit {
        // Best-effort fail-open if the service is released unexpectedly.
        if let tap = tapBox.eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
    }
}

final class TapBox: @unchecked Sendable {
    var eventTap: CFMachPort?
}
