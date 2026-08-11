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
    private(set) var isBusy = false
    var showHelp = false
    private let lockService: KeyboardLocking

    init(lockService: KeyboardLocking = KeyboardLockService()) {
        self.lockService = lockService
    }

    var isLocked: Bool {
        if case .locked = uiState { return true }
        return false
    }

    var statusText: String {
        if isBusy {
            return isLocked ? "Unlocking…" : "Locking…"
        }
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

    var primaryButtonAccessibilityHint: String {
        isLocked
            ? "Restores normal keyboard input."
            : "Blocks keyboard input so you can clean safely. Trackpad and mouse stay available."
    }

    func primaryAction() {
        if isLocked {
            unlock()
        } else {
            lock()
        }
    }

    func lock() {
        guard !isBusy else { return }
        guard AccessibilityPermission.isGranted else {
            uiState = .needsPermission
            AccessibilityPermission.requestTrustPrompt()
            return
        }

        isBusy = true
        Task { @MainActor in
            // Paint the loader before doing tap work on the main actor.
            await Task.yield()
            do {
                try lockService.start()
                uiState = .locked
            } catch let error as LocalizedError {
                uiState = .error(error.errorDescription ?? "Could not lock the keyboard.")
            } catch {
                uiState = .error("Could not lock the keyboard. Check Accessibility permission and try again.")
            }
            isBusy = false
        }
    }

    func unlock() {
        guard !isBusy else { return }
        isBusy = true
        Task { @MainActor in
            await Task.yield()
            lockService.stop()
            uiState = .idle
            isBusy = false
        }
    }

    func openAccessibilitySettings() {
        AccessibilityPermission.requestTrustPrompt()
        AccessibilityPermission.openSystemSettings()
    }

    func refreshPermissionState() {
        switch uiState {
        case .needsPermission where AccessibilityPermission.isGranted:
            uiState = .idle
        case .error where AccessibilityPermission.isGranted:
            uiState = .idle
        default:
            break
        }
    }

    /// Fail-open: always release the tap before the process exits.
    func prepareToQuit() {
        lockService.stop()
        isBusy = false
        if case .locked = uiState {
            uiState = .idle
        }
    }
}
