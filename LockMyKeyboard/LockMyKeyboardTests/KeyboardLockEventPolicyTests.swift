import CoreGraphics
import XCTest
@testable import LockMyKeyboard

final class KeyboardLockEventPolicyTests: XCTestCase {
    func testSwallowsKeyDownKeyUpFlagsChanged() {
        XCTAssertTrue(
            KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: CGEventType.keyDown.rawValue,
                systemDefinedSubtype: nil
            )
        )
        XCTAssertTrue(
            KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: CGEventType.keyUp.rawValue,
                systemDefinedSubtype: nil
            )
        )
        XCTAssertTrue(
            KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: CGEventType.flagsChanged.rawValue,
                systemDefinedSubtype: nil
            )
        )
    }

    func testSwallowsMediaFunctionSystemDefinedSubtype() {
        // F10 mute / brightness / volume arrive as NX_SYSDEFINED + subtype 8.
        XCTAssertTrue(
            KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: KeyboardLockEventPolicy.systemDefinedTypeRawValue,
                systemDefinedSubtype: KeyboardLockEventPolicy.mediaKeySubtype
            )
        )
    }

    func testPassesSystemDefinedMouseSubtype() {
        // NX_SUBTYPE_AUX_MOUSE_BUTTONS — must not block Unlock via trackpad/mouse.
        XCTAssertFalse(
            KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: KeyboardLockEventPolicy.systemDefinedTypeRawValue,
                systemDefinedSubtype: 7
            )
        )
    }

    func testFailsOpenWhenSystemDefinedSubtypeUnknown() {
        XCTAssertFalse(
            KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: KeyboardLockEventPolicy.systemDefinedTypeRawValue,
                systemDefinedSubtype: nil
            )
        )
    }

    func testPassesUnrelatedEventTypes() {
        XCTAssertFalse(
            KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: CGEventType.leftMouseDown.rawValue,
                systemDefinedSubtype: nil
            )
        )
        XCTAssertFalse(
            KeyboardLockEventPolicy.shouldSwallow(
                typeRawValue: CGEventType.scrollWheel.rawValue,
                systemDefinedSubtype: nil
            )
        )
    }

    func testEventsOfInterestIncludesSystemDefined() {
        let mask = KeyboardLockEventPolicy.eventsOfInterestMask
        let systemBit = CGEventMask(1 << KeyboardLockEventPolicy.systemDefinedTypeRawValue)
        XCTAssertEqual(mask & systemBit, systemBit)
    }
}
