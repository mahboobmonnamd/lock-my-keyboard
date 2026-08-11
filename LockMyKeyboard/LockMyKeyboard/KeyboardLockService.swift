import CoreGraphics
import Foundation
import os.log

private let log = Logger(subsystem: "com.lockmykeyboard.app", category: "KeyboardLock")

enum KeyboardLockError: LocalizedError, Equatable {
    case tapCreateFailed
    case alreadyActive

    var errorDescription: String? {
        switch self {
        case .tapCreateFailed:
            return "macOS refused to create the keyboard event tap. Confirm Accessibility permission for Lock My Keyboard, then try again."
        case .alreadyActive:
            return "The keyboard is already locked."
        }
    }
}

protocol KeyboardLocking: AnyObject {
    var isActive: Bool { get }
    func start() throws
    func stop()
}

/// Session-level CGEvent tap that swallows keyboard events while active.
///
/// Safety contract:
/// - Installs only while the user has explicitly locked.
/// - Filters keyDown / keyUp / flagsChanged only — pointer events pass through.
/// - Never logs key codes or characters.
/// - `stop()` and process termination fail open (keyboard returns to normal).
final class KeyboardLockService: KeyboardLocking, @unchecked Sendable {
    private let tapBox = TapBox()
    private var runLoopSource: CFRunLoopSource?
    private let stateLock = NSLock()

    var isActive: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return tapBox.eventTap != nil
    }

    func start() throws {
        // Tear down any previous tap without holding the lock across CF calls.
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
                        log.debug("Re-enabled event tap after system disable")
                    }
                }
                return Unmanaged.passUnretained(event)
            }
            // Swallow keyboard events. Do not inspect or log key content.
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
            log.error("CGEvent.tapCreate returned nil")
            throw KeyboardLockError.tapCreateFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        stateLock.lock()
        tapBox.eventTap = tap
        runLoopSource = source
        stateLock.unlock()

        log.info("Keyboard lock engaged")
    }

    func stop() {
        stateLock.lock()
        let source = runLoopSource
        let tap = tapBox.eventTap
        runLoopSource = nil
        tapBox.eventTap = nil
        stateLock.unlock()

        // Disable / remove outside the lock so the UI thread cannot deadlock
        // against an in-flight tap callback.
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            log.info("Keyboard lock released")
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }
}

final class TapBox: @unchecked Sendable {
    var eventTap: CFMachPort?
}
