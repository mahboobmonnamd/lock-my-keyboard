import AppKit
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

/// Pure swallow/pass rules for the CGEvent tap (unit-testable without installing a tap).
enum KeyboardLockEventPolicy {
    /// `NX_SYSDEFINED` / `NSEvent.EventType.systemDefined` — media & top-row specials.
    static let systemDefinedTypeRawValue: UInt32 = 14
    /// `NX_SUBTYPE_AUX_CONTROL_BUTTONS` — brightness, volume, mute, play/pause, etc.
    static let mediaKeySubtype: Int16 = 8

    static var eventsOfInterestMask: CGEventMask {
        CGEventMask(
            (1 << CGEventType.keyDown.rawValue)
                | (1 << CGEventType.keyUp.rawValue)
                | (1 << CGEventType.flagsChanged.rawValue)
                | (1 << systemDefinedTypeRawValue)
        )
    }

    /// Whether a tapped event should be swallowed while locked.
    ///
    /// - Media/function specials arrive as systemDefined + subtype 8.
    /// - Other systemDefined subtypes (e.g. mouse buttons = 7) pass through so Unlock stays clickable.
    /// - Unknown subtype fails open (pass) for the same reason.
    static func shouldSwallow(typeRawValue: UInt32, systemDefinedSubtype: Int16?) -> Bool {
        switch typeRawValue {
        case CGEventType.keyDown.rawValue,
             CGEventType.keyUp.rawValue,
             CGEventType.flagsChanged.rawValue:
            return true
        case systemDefinedTypeRawValue:
            guard let systemDefinedSubtype else { return false }
            return systemDefinedSubtype == mediaKeySubtype
        default:
            return false
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
/// - Filters keyDown / keyUp / flagsChanged and media/function systemDefined keys —
///   pointer events (including systemDefined mouse subtypes) pass through.
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

            var systemDefinedSubtype: Int16?
            if type.rawValue == KeyboardLockEventPolicy.systemDefinedTypeRawValue {
                systemDefinedSubtype = NSEvent(cgEvent: event)?.subtype.rawValue
            }

            if KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: type.rawValue,
                systemDefinedSubtype: systemDefinedSubtype
            ) {
                // Swallow keyboard / media-key events. Do not inspect or log key content.
                return nil
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: KeyboardLockEventPolicy.eventsOfInterestMask,
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
