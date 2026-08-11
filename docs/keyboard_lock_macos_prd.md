# PRODUCT REQUIREMENTS DOCUMENT

# Keyboard Lock for macOS

A safe, one-click cleaning mode that prevents accidental keypresses while wiping a MacBook keyboard.

| Field | Value |
| --- | --- |
| Status | Draft for product and engineering review |
| Version | 1.0 |
| Date | 10 August 2026 |
| Platform | macOS; MacBook-first experience |
| Primary user | Anyone cleaning a MacBook or external keyboard |

**Product decision.** Build a lightweight menu-bar utility with a large, mouse-accessible lock state, an always-visible countdown, and a guaranteed recovery path. Keyboard input is disabled only after the user explicitly starts the timer.

---

## 1. Executive summary

Keyboard Lock for macOS lets a user temporarily disable keyboard input while cleaning a MacBook. The user starts a cleaning session from the menu bar, sees a clear locked-state overlay and countdown, wipes the keyboard without accidental typing or shortcuts, and releases the lock using the trackpad or mouse.

The product is intentionally narrow: it is not a privacy lock, screen lock, child-safety tool, or input-remapping utility. Its value is preventing accidental keypresses during a short, physical cleaning task while keeping the user in control and avoiding lockout risk.

## 2. Problem and opportunity

### 2.1 Problem statement

Cleaning a MacBook keyboard often causes unintended keystrokes: text is inserted, applications receive shortcuts, windows move, media plays, and destructive actions may be triggered. Closing applications or putting the MacBook to sleep is inconvenient and does not fully prevent input if the device wakes or the user needs the screen visible.

### 2.2 Opportunity

A focused cleaning mode can solve the problem with almost no learning curve: start, clean, release. Trust will come from predictable behavior, strong visual feedback, a visible timer, and recovery options that do not depend on the keyboard working.

## 3. Goals and non-goals

### 3.1 Goals

- Prevent ordinary keyboard input from reaching foreground apps during an active cleaning session.
- Make the state obvious before, during, and after the lock.
- Allow release using only the mouse or trackpad.
- Prevent accidental permanent lockout with a default timeout and emergency recovery path.
- Keep the app lightweight, local-first, and respectful of user privacy.

### 3.2 Non-goals for MVP

- Locking the display, hiding files, or replacing the macOS login screen.
- Blocking the trackpad, mouse, Touch ID, power button, lid close, or other non-keyboard controls.
- Cleaning guidance, liquid detection, hardware diagnostics, or keyboard repair workflows.
- Remote administration, cloud sync, accounts, ads, or telemetry that leaves the device.
- Support for arbitrary per-application key remapping or macro creation.

## 4. Target users and use cases

| User | Situation | Desired outcome |
| --- | --- | --- |
| MacBook owner | Wiping dust, fingerprints, or crumbs from the keyboard. | Clean without text appearing or shortcuts firing. |
| IT / office support | Cleaning several company laptops between users. | Start and release quickly with consistent behavior. |
| Caregiver / parent | Cleaning a shared MacBook while a child is nearby. | Avoid accidental input without shutting down the device. |

### 4.1 Primary use case

1. User clicks the Keyboard Lock icon in the macOS menu bar.
2. User chooses a duration, or accepts the default cleaning timer.
3. The app shows a three-second visual countdown, then enters Locked state.
4. User cleans the keyboard. Keypresses are ignored by normal applications.
5. User clicks Release Lock in the overlay or menu-bar menu.
6. The app confirms the keyboard is active again and returns to Idle state.

## 5. Experience requirements

### 5.1 States

| State | Visible UI | Input behavior | Exit |
| --- | --- | --- | --- |
| Idle | Menu-bar icon; no overlay. | Normal keyboard and pointer input. | Start Lock |
| Arming | Large countdown: 3, 2, 1; cancel button. | Keyboard remains active until Locked. | Cancel or Locked |
| Locked | Screen overlay with lock icon, timer, and Release Lock button. | Keyboard input is suppressed; pointer remains active. | Release, timeout, or app quit |
| Released | Short confirmation, then return to Idle. | Normal input restored. | Automatic |
| Recovery | Recovery instructions or system notification. | Normal input restored where possible. | User action |

### 5.2 Start flow

- Menu-bar icon is always available while the app is running.
- Menu offers Start Keyboard Lock and a duration selector: 5, 10, 15, 30, or 60 minutes. Default: 10 minutes.
- A compact pre-lock confirmation states: Keyboard input will be disabled; pointer remains available; release with the on-screen button.
- The user can cancel during the three-second arming countdown.

### 5.3 Locked state

**Locked-state rule.** The lock must be visually unmistakable and reversible with the pointer. The overlay should not look like a system error or login screen.

- A centered, always-on-top overlay displays a lock icon, "Keyboard Locked", remaining time, and a prominent Release Lock button.
- The overlay uses a calm, high-contrast design and does not cover the entire screen unless required for reliable pointer access.
- A small menu-bar indicator changes appearance while locked.
- The countdown updates at least once per second and remains visible even when the user changes applications.
- Clicks and pointer movement continue to work. The app must not capture or block pointer events.

### 5.4 Release and recovery

- **Primary release:** click Release Lock on the overlay.
- **Secondary release:** open the menu-bar item and click Release Lock.
- **Timeout:** automatically release at the end of the selected duration. A final 10-second warning is shown.
- **App quit:** quitting the app must restore normal keyboard input before termination when technically possible.
- **Emergency recovery:** provide a documented macOS recovery step for cases where the app is unresponsive, such as force-quitting the app from Activity Monitor or restarting the Mac.

## 6. Functional requirements

| ID | Capability | Requirement | Priority |
| --- | --- | --- | --- |
| PRD-001 | Start lock | User can start a lock session from the menu bar. | P0 |
| PRD-002 | Explicit arming | App shows a visible three-second countdown and allows cancellation before suppression begins. | P0 |
| PRD-003 | Keyboard suppression | While Locked, ordinary key-down and key-up events do not reach foreground applications. | P0 |
| PRD-004 | Pointer access | Trackpad and mouse clicks remain available for release actions. | P0 |
| PRD-005 | Visible status | Overlay and menu-bar indicator clearly show whether the keyboard is locked. | P0 |
| PRD-006 | Duration | User can choose a timer; the app releases automatically when it expires. | P0 |
| PRD-007 | Manual release | User can release with a pointer-only action from the overlay or menu bar. | P0 |
| PRD-008 | Safe quit | App attempts to restore input before quit and does not leave a persistent system-wide block. | P0 |
| PRD-009 | Launch behavior | App can launch at login, but lock is never enabled automatically at launch. | P1 |
| PRD-010 | Preferences | User can set default duration, launch-at-login, overlay opacity, and sound/vibration feedback where supported. | P1 |
| PRD-011 | Accessibility | Controls have accessible labels, support VoiceOver where feasible, and maintain sufficient contrast. | P1 |
| PRD-012 | External keyboards | Lock applies to the MacBook keyboard and attached standard keyboards detected by the same event path, subject to macOS limitations. | P1 |

## 7. Safety, permissions, and trust

### 7.1 Safety principles

- **No silent activation:** locking begins only after an explicit user action.
- **Fail open:** if the app crashes or loses its event tap, normal keyboard behavior should be restored as soon as possible.
- **No indefinite default:** a finite timer is selected by default; any "No timeout" option, if added later, must require an extra confirmation.
- Do not interfere with power, lid, Touch ID, or system recovery behavior.
- Before first use, explain why macOS may request Accessibility permission and how the permission is used.

### 7.2 Permission experience

Because keyboard suppression may require macOS Accessibility or input-monitoring capabilities, onboarding must explain the permission in plain language: the app needs permission to intercept keyboard events only while the user has activated Keyboard Lock. The app must provide a link or button to the relevant System Settings page and a clear diagnostic if permission is missing.

### 7.3 Privacy

- No keystrokes are recorded, stored, transmitted, or used for analytics.
- No account or network connection is required for core functionality.
- Diagnostics, if added, must contain only app state and error codes, never key values or typed content.

## 8. Technical considerations

The implementation should use a native macOS app, preferably a small Swift/SwiftUI utility with a menu-bar presence and a lightweight overlay window. Keyboard interception can be implemented through the macOS event-monitoring and event-tap mechanisms appropriate to the supported OS versions, subject to Accessibility/Input Monitoring permission and Apple platform constraints.

| Area | Direction |
| --- | --- |
| App lifecycle | Menu-bar utility; no main window required for normal use. |
| State machine | Idle → Arming → Locked → Released/Recovery; one authoritative state source. |
| Event handling | Suppress key events only in Locked state; pass through all events in every other state. |
| Overlay | Always-on-top, pointer-interactive, non-destructive, and resilient to app switching. |
| Timer | Monotonic timer; persist only user preferences, not active keystrokes. |
| Testing | Test built-in keyboard, external keyboard, modifier keys, media/function keys, app switching, sleep/wake, permission changes, crash/quit, and timer expiry. |

**Implementation caution.** macOS security and event-monitoring behavior varies by OS release and permission state. Engineering must validate the event path on the minimum supported macOS version before committing to a release date.

## 9. Edge cases and expected behavior

| Scenario | Expected behavior |
| --- | --- |
| Accessibility permission missing | Do not enter Locked state. Explain the missing permission and provide setup guidance. |
| User switches applications | Overlay remains available; keyboard remains suppressed until release or timeout. |
| Mac goes to sleep | On wake, restore or safely terminate the lock state; never leave the user without a recovery path. |
| External keyboard connected while locked | Suppress it if supported by the selected event path; otherwise show a limitation in the help text. |
| User clicks outside overlay | Keep the session locked and leave the overlay/menu-bar release path available. |
| App is force-quit | System should return to normal input; document restart/Activity Monitor recovery if platform behavior differs. |
| Timer reaches zero | Release lock, show a brief confirmation, and return to Idle. |

## 10. Success metrics

MVP success is primarily behavioral and trust-based. Metrics should be local or opt-in; the product must not collect typed content.

| Metric | Target / signal |
| --- | --- |
| Successful lock sessions | At least 99% of attempted sessions enter Locked state when permission is granted. |
| Successful release | 100% of normal sessions release by button, menu bar, timeout, or documented recovery. |
| Accidental input during lock | Zero keypresses delivered to tested foreground apps during a healthy Locked session. |
| Time to start | User can begin locking within two clicks from the menu bar after first-time setup. |
| User confidence | Users understand the lock state and release path without reading a long guide. |

## 11. Acceptance criteria

1. Given required permission is granted, when the user starts a session, then the app displays the arming countdown and enters Locked state after three seconds unless cancelled.
2. Given Locked state is active, when the user presses letters, numbers, modifiers, navigation keys, or common shortcuts, then tested foreground applications receive no corresponding keyboard input.
3. Given Locked state is active, when the user clicks Release Lock using the trackpad or mouse, then keyboard input is restored within one second and the overlay closes.
4. Given a finite timer is selected, when it expires, then the app releases the lock automatically and shows a confirmation.
5. Given the app is not Locked, when the user types, then all keyboard input behaves normally.
6. Given permission is missing or revoked, when the user tries to start, then the app refuses to lock and explains the required setup.
7. Given the app is quit normally, then it restores normal keyboard input before exit.
8. Given the user opens the app for the first time, then the app explains the permission, lock behavior, timer, and pointer-only release path.

## 12. MVP release plan

| Phase | Scope | Exit condition |
| --- | --- | --- |
| MVP | Menu-bar utility, permission onboarding, arming countdown, keyboard suppression, overlay, pointer release, timer, safe quit. | All P0 requirements and acceptance criteria pass on supported MacBook models. |
| Hardening | Sleep/wake handling, external keyboards, accessibility improvements, crash recovery, broader OS-version matrix. | No critical recovery or permission defects in beta testing. |
| Later | Custom cleaning presets, optional audio/haptic feedback, usage history without key data, optional shortcut to open the lock menu. | Only if they preserve the narrow, safe cleaning-mode experience. |

## 13. Open decisions

- Minimum supported macOS version and supported Mac hardware range.
- Whether the overlay should be full-screen or a centered floating panel in MVP.
- Whether an optional "No timeout" mode is needed, and what additional safeguards it requires.
- Whether sound, haptic feedback, or a menu-bar-only experience is preferred for accessibility and quiet environments.
- Final product name and icon design.

---

**One-line product definition.** A macOS menu-bar utility that temporarily suppresses keyboard input so users can clean a MacBook safely, with a visible timer and mouse-only release.
