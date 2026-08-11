import ApplicationServices
import Cocoa
import Foundation

/// Minimal spike: prove CGEvent tap can suppress keyboard events on macOS 26 arm64
/// while leaving the pointer free, then restore on unlock / quit.

/// Holds the mach port for the C callback without MainActor isolation.
final class TapBox: @unchecked Sendable {
    var eventTap: CFMachPort?
}

@MainActor
final class KeyboardLockSpike: NSObject {
    private enum State {
        case idle
        case locked
    }

    private var state: State = .idle
    private let tapBox = TapBox()
    private var runLoopSource: CFRunLoopSource?
    private var statusLabel: NSTextField!
    private var toggleButton: NSButton!

    func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Lock My Keyboard — Spike"
        window.center()
        window.isReleasedWhenClosed = false

        let content = NSView(frame: window.contentView!.bounds)
        content.autoresizingMask = [.width, .height]

        statusLabel = NSTextField(labelWithString: "Idle — type in another app to verify")
        statusLabel.frame = NSRect(x: 24, y: 120, width: 372, height: 48)
        statusLabel.maximumNumberOfLines = 3
        statusLabel.font = .systemFont(ofSize: 13)
        content.addSubview(statusLabel)

        toggleButton = NSButton(
            title: "Lock Keyboard",
            target: self,
            action: #selector(toggle)
        )
        toggleButton.bezelStyle = .rounded
        toggleButton.frame = NSRect(x: 120, y: 48, width: 180, height: 32)
        content.addSubview(toggleButton)

        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.unlock(reason: "quit")
            }
        }

        print("[spike] launched on \(ProcessInfo.processInfo.operatingSystemVersionString) \(unameArch())")
        print("[spike] Accessibility trusted: \(AXIsProcessTrusted())")
        app.run()
    }

    @objc private func toggle() {
        switch state {
        case .idle:
            lock()
        case .locked:
            unlock(reason: "button")
        }
    }

    private func lock() {
        if !AXIsProcessTrusted() {
            promptForAccessibility()
            statusLabel.stringValue =
                "Accessibility permission required. Enable this app in System Settings → Privacy & Security → Accessibility, then click Lock again."
            print("[spike] FAIL permission — Accessibility not trusted")
            return
        }

        guard installTap() else {
            statusLabel.stringValue = "Could not create event tap. Check Accessibility permission."
            print("[spike] FAIL tapCreate returned nil")
            return
        }

        state = .locked
        toggleButton.title = "Unlock Keyboard"
        statusLabel.stringValue = "LOCKED — keyboard events filtered. Click Unlock or quit to restore."
        print("[spike] PASS locked — event tap active")
    }

    private func unlock(reason: String) {
        removeTap()
        let wasLocked = state == .locked
        state = .idle
        toggleButton?.title = "Lock Keyboard"
        if wasLocked || reason == "quit" {
            statusLabel?.stringValue = "Idle — keyboard restored (\(reason))"
            print("[spike] PASS unlocked via \(reason)")
        }
    }

    private func promptForAccessibility() {
        // String form avoids Swift 6 shared-mutable CFString constant diagnostics.
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    private func installTap() -> Bool {
        removeTap()

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
                        print("[spike] re-enabled tap after system disable")
                    }
                }
                return Unmanaged.passUnretained(event)
            }

            // Suppress keyboard events while tap is installed (only installed when locked).
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
            return false
        }

        tapBox.eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func removeTap() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = tapBox.eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            tapBox.eventTap = nil
        }
    }
}

private func unameArch() -> String {
    var info = utsname()
    uname(&info)
    return withUnsafePointer(to: &info.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
    }
}

if CommandLine.arguments.contains("--verify") {
    exit(SpikeVerify.run())
}

KeyboardLockSpike().run()
