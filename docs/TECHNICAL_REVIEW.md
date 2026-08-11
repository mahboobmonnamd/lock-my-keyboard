# Technical Review — Lock My Keyboard

**Status:** Approved for spike + MVP  
**Date:** 11 August 2026  
**Product:** Lock My Keyboard  
**Reviewers:** Product + Engineering (initial)

## 1. Purpose

Validate the technical approach for a **simple one-window macOS desktop app** that temporarily suppresses keyboard input so the user can clean a MacBook keyboard, then unlock with a mouse/trackpad click.

This review supersedes the earlier menu-bar / multi-duration PRD direction for MVP scope.

## 2. Product constraints (locked)

| Constraint | Decision |
| --- | --- |
| Product name | **Lock My Keyboard** |
| Form factor | Single-window desktop app (not menu-bar utility) |
| UI | Keyboard image on top; Lock / Unlock control below |
| Platform | **Apple Silicon only** (`arm64`) |
| OS | **macOS 26** only (current host: 26.5.x) — one OS baseline, no multi-version branching |
| Complexity | No timers, no preferences, no cloud, no accounts, no telemetry |
| Personas | Person cleaning a keyboard only (no caregiver / IT workflows) |

## 3. Proposed architecture

```
┌─────────────────────────────────────┐
│  SwiftUI App (one window)           │
│  ┌─────────────┐  ┌───────────────┐ │
│  │ Keyboard UI │  │ Lock / Unlock │ │
│  └─────────────┘  └───────────────┘ │
│              │                      │
│              ▼                      │
│     AppState (Idle | Locked)        │
│              │                      │
│              ▼                      │
│   KeyboardLockService               │
│   (CGEvent tap lifecycle)           │
└─────────────────────────────────────┘
```

- **UI layer:** SwiftUI, one scene/window.
- **State:** Binary `idle` / `locked` (plus transient `permissionRequired` for onboarding).
- **Input layer:** `CGEvent.tapCreate` (HID session-level) filters key-down / key-up / flags-changed while locked; pointer events pass through.
- **Permissions:** macOS Accessibility (and Input Monitoring if required by the chosen API path). App refuses to lock until granted.

## 4. Feasibility

| Topic | Assessment | Risk |
| --- | --- | --- |
| Keyboard suppress via event tap | Standard approach for local utilities; well documented | Medium — OS policy / Secure Input edge cases |
| Pointer remains usable | Event tap can filter keyboard events only | Low |
| Fail-open on quit/crash | Disable tap on terminate; system drops tap if process dies | Low–Medium — must verify in spike |
| Single OS + Apple Silicon | Removes Rosetta, older API shims, multi-SDK conditionals | Low |
| App Store distribution | Accessibility-heavy apps are often easier as notarized direct download | Medium (post-MVP) |
| One-screen UX | Trivial; no navigation stack | Low |

**Verdict:** Feasible for MVP if the spike proves reliable suppress + unlock + fail-open on macOS 26 arm64.

## 5. Spike goals (must pass before UI polish)

1. Create event tap after Accessibility permission is granted.
2. Suppress letter/number/modifier keys from reaching a foreground TextEdit / Notes window.
3. Leave trackpad/mouse clicks working so Unlock can be clicked.
4. Unlock restores typing within ~1s.
5. Quit while locked restores typing (fail-open).
6. Force-quit while locked restores typing (document if any delay).

## 6. Out of scope for MVP

- Menu bar extra / accessory app
- Duration timers and auto-unlock
- Launch at login
- External-keyboard special casing beyond “same event path”
- Preferences, sounds, haptics, analytics
- Intel Macs, older macOS versions

## 7. Open items resolved by this review

| Item | Resolution |
| --- | --- |
| Overlay vs window | **Main window UI** with clear locked visual state (no full-screen system-like overlay required for MVP) |
| Menu bar | **Not required** for MVP |
| Min OS / arch | **macOS 26 + arm64 only** |
| Name | **Lock My Keyboard** |
| Timer | **None** — user unlocks manually |

## 8. Recommendation

Proceed in this order:

1. ADRs (platform, architecture, input interception)
2. Spec (behavior + acceptance)
3. Spike (`spike/` executable)
4. Public GitHub repo with docs + spike results
5. MVP implementation

**Gate:** Do not ship UI polish until spike checklist in §5 is green.
