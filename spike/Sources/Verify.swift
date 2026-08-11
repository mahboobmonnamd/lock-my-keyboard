import ApplicationServices
import CoreGraphics
import Foundation

/// `swift run KeyboardLockSpike --verify` — non-GUI gate for CI / preflight.
enum SpikeVerify {
    static func run() -> Int32 {
        print("[verify] host: \(ProcessInfo.processInfo.operatingSystemVersionString) \(arch())")
        let trusted = AXIsProcessTrusted()
        print("[verify] accessibilityTrusted=\(trusted)")

        guard trusted else {
            print("[verify] FAIL: Accessibility not granted to this process")
            print("[verify] Grant access, then re-run: swift run KeyboardLockSpike --verify")
            return 2
        }

        let mask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { _, _, event, _ in
            Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: nil
        ) else {
            print("[verify] FAIL: CGEvent.tapCreate returned nil")
            return 3
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[verify] PASS: event tap created and enabled")

        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        print("[verify] PASS: event tap disabled (fail-open path)")
        print("[verify] RESULT: PASS (manual key-suppression still required via GUI spike)")
        return 0
    }

    private static func arch() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }
}
