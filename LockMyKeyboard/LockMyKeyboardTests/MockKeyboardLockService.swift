import Foundation
@testable import LockMyKeyboard

final class MockKeyboardLockService: KeyboardLocking, @unchecked Sendable {
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    var startError: Error?
    var activationSucceeds = true
    private(set) var active = false

    var isActive: Bool { active }

    func start() throws {
        startCallCount += 1
        if let startError {
            throw startError
        }
        active = activationSucceeds
    }

    func stop() {
        stopCallCount += 1
        active = false
    }

    func simulateUnexpectedStop() {
        active = false
    }
}
