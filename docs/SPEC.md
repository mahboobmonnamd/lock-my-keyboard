# Spec — Lock My Keyboard (MVP)

**Version:** 0.1  
**Date:** 11 August 2026  
**Depends on:** [Technical Review](./TECHNICAL_REVIEW.md), ADRs 0001–0003

## 1. Summary

Lock My Keyboard is a one-window macOS app for Apple Silicon (macOS 26). The user opens the app, clicks **Lock**, cleans the physical keyboard without typing into apps, then clicks **Unlock**.

## 2. User-facing behavior

### 2.1 Window

- Single window titled **Lock My Keyboard**.
- Layout (top → bottom):
  1. Product name
  2. Keyboard image / illustration
  3. Primary button: **Lock** (when idle) or **Unlock** (when locked)
  4. Status line under the button
- While locked, window should stay easy to reach (prefer `floating` / elevated window level so Unlock remains clickable).

### 2.2 States

| State | Button | Status copy (approx.) | Keyboard input |
| --- | --- | --- | --- |
| Idle | Lock | Ready to lock | Normal |
| Needs permission | Lock (or Open Settings) | Accessibility permission required | Normal |
| Locked | Unlock | Keyboard locked — click Unlock when done | Suppressed |

### 2.3 Flows

**First launch / missing permission**

1. User clicks Lock.
2. App detects missing Accessibility trust.
3. App shows guidance and a control to open System Settings → Privacy & Security → Accessibility.
4. App does **not** enter Locked until permission is granted.

**Lock**

1. Permission OK → enter Locked.
2. Install event tap; suppress keyboard events.
3. UI shows Unlock + locked status; keyboard art reflects locked state.

**Unlock**

1. User clicks Unlock (pointer).
2. Remove/disable event tap.
3. Return to Idle; typing works again within 1 second.

**Quit while locked**

1. App disables tap before exit.
2. Typing works after quit.

## 3. Functional requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| SPEC-001 | One-window SwiftUI app named Lock My Keyboard | P0 |
| SPEC-002 | Show keyboard image and Lock/Unlock control | P0 |
| SPEC-003 | Lock suppresses keyDown/keyUp/flagsChanged to other apps | P0 |
| SPEC-004 | Pointer remains usable to Unlock | P0 |
| SPEC-005 | Unlock restores input within 1s | P0 |
| SPEC-006 | Refuse Lock without Accessibility permission + link to Settings | P0 |
| SPEC-007 | Quit while locked restores input (fail-open) | P0 |
| SPEC-008 | arm64 + macOS 26 only | P0 |
| SPEC-009 | No keystroke logging or network use | P0 |

## 4. Non-requirements (MVP)

- Menu bar icon / agent
- Timers / auto-unlock
- Preferences
- Launch at login
- Intel / older macOS
- Caregiver or IT multi-machine workflows

## 5. Technical shape

- Language: Swift
- UI: SwiftUI
- Input: `KeyboardLockService` wrapping CGEvent tap (ADR 0003)
- Bundle: standard `.app` (required for Accessibility trust UX)
- Deployment: local run / notarized distribute later (not App Store for MVP unless revisited)

## 6. Acceptance criteria

1. On macOS 26 arm64 with Accessibility granted, Lock stops letters, numbers, and common modifiers from reaching Notes/TextEdit.
2. Trackpad click on Unlock restores typing within 1 second.
3. Without Accessibility, Lock does not suppress keys and explains how to grant permission.
4. Quitting the app while Locked restores typing.
5. App UI matches §2.1 (keyboard image + Lock/Unlock).
6. Binary is arm64 and declares macOS 26 deployment target.

## 7. Spike checklist (gate)

Record results in `spike/RESULTS.md` before calling MVP done:

- [ ] Tap creates with permission
- [ ] Keys suppressed
- [ ] Pointer works
- [ ] Unlock restores
- [ ] Quit restores
- [ ] Force-quit restores (or documented)

## 8. Implementation order

1. Spike package validating CGEvent tap
2. App skeleton + `AppState`
3. `KeyboardLockService`
4. UI (keyboard image + button)
5. Permission onboarding
6. Manual test against §6
