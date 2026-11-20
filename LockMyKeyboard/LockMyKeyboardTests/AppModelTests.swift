import XCTest
@testable import LockMyKeyboard

@MainActor
final class AppModelTests: XCTestCase {
    func testLockSucceedsWhenPermissionGranted() async {
        let service = MockKeyboardLockService()
        let model = AppModel(
            lockService: service,
            isAccessibilityGranted: { true },
            requestAccessibility: {},
            openAccessibilitySettings: {}
        )

        model.lock()
        let finished = await model.waitUntilIdle()
        XCTAssertTrue(finished)
        XCTAssertFalse(model.isBusy)
        XCTAssertTrue(model.isLocked)
        XCTAssertEqual(model.uiState, .locked)
        XCTAssertEqual(service.startCallCount, 1)
        XCTAssertEqual(model.primaryButtonTitle, "Unlock")
    }

    func testLockRequiresAccessibility() {
        var prompted = false
        let service = MockKeyboardLockService()
        let model = AppModel(
            lockService: service,
            isAccessibilityGranted: { false },
            requestAccessibility: { prompted = true },
            openAccessibilitySettings: {}
        )

        model.lock()

        XCTAssertEqual(model.uiState, .needsPermission)
        XCTAssertTrue(prompted)
        XCTAssertEqual(service.startCallCount, 0)
        XCTAssertFalse(model.isLocked)
    }

    func testUnlockStopsServiceAndReturnsIdle() async {
        let service = MockKeyboardLockService()
        let model = AppModel(
            lockService: service,
            isAccessibilityGranted: { true },
            requestAccessibility: {},
            openAccessibilitySettings: {}
        )

        model.lock()
        let locked = await model.waitUntilIdle()
        XCTAssertTrue(locked)
        XCTAssertTrue(model.isLocked)

        model.unlock()
        let unlocked = await model.waitUntilIdle()
        XCTAssertTrue(unlocked)

        XCTAssertEqual(model.uiState, .idle)
        XCTAssertFalse(model.isLocked)
        XCTAssertEqual(service.stopCallCount, 1)
        XCTAssertEqual(model.primaryButtonTitle, "Lock")
    }

    func testLockSurfacesServiceFailure() async {
        let service = MockKeyboardLockService()
        service.startError = KeyboardLockError.tapCreateFailed
        let model = AppModel(
            lockService: service,
            isAccessibilityGranted: { true },
            requestAccessibility: {},
            openAccessibilitySettings: {}
        )

        model.lock()
        let finished = await model.waitUntilIdle()
        XCTAssertTrue(finished)

        guard case .error(let message) = model.uiState else {
            return XCTFail("Expected error state, got \(model.uiState)")
        }
        XCTAssertFalse(message.isEmpty)
        XCTAssertFalse(model.isLocked)
    }

    func testPrepareToQuitFailsOpen() async {
        let service = MockKeyboardLockService()
        let model = AppModel(
            lockService: service,
            isAccessibilityGranted: { true },
            requestAccessibility: {},
            openAccessibilitySettings: {}
        )

        model.lock()
        let finished = await model.waitUntilIdle()
        XCTAssertTrue(finished)
        model.prepareToQuit()

        XCTAssertEqual(model.uiState, .idle)
        XCTAssertGreaterThanOrEqual(service.stopCallCount, 1)
        XCTAssertFalse(service.isActive)
    }

    func testRefreshPermissionClearsNeedsPermission() {
        final class Flag: @unchecked Sendable { var value = false }
        let flag = Flag()
        let model = AppModel(
            lockService: MockKeyboardLockService(),
            isAccessibilityGranted: { flag.value },
            requestAccessibility: {},
            openAccessibilitySettings: {}
        )

        model.lock()
        XCTAssertEqual(model.uiState, .needsPermission)

        flag.value = true
        model.refreshPermissionState()
        XCTAssertEqual(model.uiState, .idle)
    }

    func testLostTapClearsLockedStateAndWarns() async {
        let service = MockKeyboardLockService()
        let model = AppModel(
            lockService: service,
            isAccessibilityGranted: { true },
            requestAccessibility: {},
            openAccessibilitySettings: {}
        )

        model.lock()
        let locked = await model.waitUntilIdle()
        XCTAssertTrue(locked)
        service.simulateUnexpectedStop()
        model.refreshLockHealth()

        XCTAssertFalse(model.isLocked)
        XCTAssertFalse(service.isActive)
        XCTAssertEqual(model.primaryButtonTitle, "Lock")
        guard case .error(let message) = model.uiState else {
            return XCTFail("Expected warning after event tap failure")
        }
        XCTAssertTrue(message.contains("stopped unexpectedly"))
        XCTAssertTrue(message.contains("Typing may be active"))
        XCTAssertGreaterThanOrEqual(service.stopCallCount, 1)

        // Re-entering the app must not erase a genuine protection-loss warning.
        model.refreshPermissionState()
        XCTAssertEqual(model.uiState, .error(message))
        model.prepareToQuit()
    }

    func testRevokedAccessibilityStopsActiveTap() async {
        final class PermissionFlag: @unchecked Sendable { var granted = true }
        let permission = PermissionFlag()
        let service = MockKeyboardLockService()
        let model = AppModel(
            lockService: service,
            isAccessibilityGranted: { permission.granted },
            requestAccessibility: {},
            openAccessibilitySettings: {}
        )

        model.lock()
        let locked = await model.waitUntilIdle()
        XCTAssertTrue(locked)
        permission.granted = false
        model.refreshLockHealth()

        XCTAssertFalse(model.isLocked)
        XCTAssertFalse(service.isActive)
        XCTAssertGreaterThanOrEqual(service.stopCallCount, 1)
        model.prepareToQuit()
    }

    func testStatusAfterLock() async {
        let model = AppModel(
            lockService: MockKeyboardLockService(),
            isAccessibilityGranted: { true },
            requestAccessibility: {},
            openAccessibilitySettings: {}
        )
        model.lock()
        let finished = await model.waitUntilIdle()
        XCTAssertTrue(finished)
        XCTAssertEqual(model.statusText, "Keyboard locked — click Unlock when you are done.")
    }
}
