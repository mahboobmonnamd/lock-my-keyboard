import XCTest
@testable import LockMyKeyboard

final class KeyboardLockErrorTests: XCTestCase {
    func testTapCreateFailedHasUserFacingDescription() {
        let description = KeyboardLockError.tapCreateFailed.errorDescription
        XCTAssertNotNil(description)
        XCTAssertFalse(description!.isEmpty)
    }

    func testErrorsAreEquatable() {
        XCTAssertEqual(KeyboardLockError.tapCreateFailed, KeyboardLockError.tapCreateFailed)
        XCTAssertNotEqual(KeyboardLockError.tapCreateFailed, KeyboardLockError.alreadyActive)
    }
}
