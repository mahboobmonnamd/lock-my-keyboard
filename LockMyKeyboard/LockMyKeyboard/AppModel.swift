import AppKit
import ApplicationServices
import Foundation
import Observation

enum LockUIState: Equatable {
    case idle
    case locked
    case needsPermission
    case error(String)
}

@Observable
@MainActor
final class AppModel {
    private(set) var uiState: LockUIState = .idle
    private let lockService = KeyboardLockService()

    var isLocked: Bool {
        if case .locked = uiState { return true }
        return false
    }

    var statusText: String {
        switch uiState {
        case .idle:
            return "Ready — click Lock before you clean the keyboard."
        case .locked:
            return "Keyboard locked — click Unlock when you are done."
        case .needsPermission:
            return "Accessibility permission is required to lock the keyboard."
        case .error(let message):
            return message
        }
    }

    var primaryButtonTitle: String {
        isLocked ? "Unlock" : "Lock"
    }

    func primaryAction() {
        if isLocked {
            unlock()
        } else {
            lock()
        }
    }

    func lock() {
        guard AXIsProcessTrusted() else {
            uiState = .needsPermission
            promptForAccessibility()
            return
        }

        do {
            try lockService.start()
            uiState = .locked
        } catch {
            uiState = .error("Could not lock the keyboard. Check Accessibility permission and try again.")
        }
    }

    func unlock() {
        lockService.stop()
        uiState = .idle
    }

    func openAccessibilitySettings() {
        promptForAccessibility()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func refreshPermissionState() {
        if case .needsPermission = uiState, AXIsProcessTrusted() {
            uiState = .idle
        }
    }

    func prepareToQuit() {
        lockService.stop()
    }

    private func promptForAccessibility() {
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}
