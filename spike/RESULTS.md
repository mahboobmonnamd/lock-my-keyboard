# Spike results — CGEvent keyboard lock

**Date:** 11 August 2026  
**Host:** macOS 26.5.2 (Build 25F84), arm64, Xcode 26.6  
**Binary:** `swift run KeyboardLockSpike` from `spike/`

## Automated preflight (`--verify`)

```text
[verify] host: Version 26.5.2 (Build 25F84) arm64
[verify] accessibilityTrusted=false
[verify] FAIL: Accessibility not granted to this process
```

| Gate | Result | Notes |
| --- | --- | --- |
| Package builds on macOS 26 arm64 | **PASS** | `swift-tools-version: 6.2`, `.macOS(.v26)` |
| `--verify` reports trust state | **PASS** | Exit 2 until Accessibility granted |
| Tap creates with Accessibility permission | **Blocked on permission** | Re-run after granting trust to `KeyboardLockSpike` / `swift` |
| Keys suppressed in another app | Pending GUI run | |
| Pointer / Unlock button works while locked | Pending GUI run | |
| Unlock restores typing | Pending GUI run | |
| Quit while locked restores typing | Pending GUI run | Implemented via `willTerminate` |
| Force-quit restores typing | Pending GUI run | Expected: process death drops tap |

## How to finish the spike (2 minutes)

```bash
cd spike
swift run KeyboardLockSpike
```

1. When prompted, allow Accessibility (System Settings → Privacy & Security → Accessibility).
2. Confirm with: `swift run KeyboardLockSpike --verify` → expect `RESULT: PASS`.
3. In the GUI: Lock → type in Notes (no input) → Unlock → typing returns → Lock → Quit → typing returns.

## Engineering conclusion so far

- ADR 0003 approach **compiles and links** on the target platform.
- Permission gate behaves correctly (refuse path when untrusted).
- Full suppress/restore confirmation needs one local Accessibility grant (cannot be completed from an unattended agent session).

**ADR 0003 status:** Accepted for implementation; complete the GUI checklist above on first developer machine setup.
