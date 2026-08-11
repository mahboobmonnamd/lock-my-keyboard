# Lock My Keyboard

A simple macOS app for Apple Silicon that temporarily disables the keyboard so you can clean it without accidental typing.

**Lock → clean → Unlock.** One window. No menu bar complexity. No timers. No accounts.

## Platform

| | |
| --- | --- |
| CPU | Apple Silicon (`arm64`) only |
| OS | macOS 26 only |
| UI | Single window — keyboard image + Lock/Unlock |

## Docs

1. [Technical Review](docs/TECHNICAL_REVIEW.md)
2. [ADRs](docs/adr/)
3. [Spec](docs/SPEC.md)
4. [Original PRD (superseded for MVP shape)](docs/keyboard_lock_macos_prd.md)
5. [Spike results](spike/RESULTS.md)

## Run the app

```bash
open LockMyKeyboard/LockMyKeyboard.xcodeproj
```

Or:

```bash
cd LockMyKeyboard
xcodebuild -scheme LockMyKeyboard -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug/LockMyKeyboard.app
```

Grant **Accessibility** on first Lock (System Settings → Privacy & Security → Accessibility).

## Spike

```bash
cd spike
swift run KeyboardLockSpike
# or headless:
swift run KeyboardLockSpike --verify
```

## Status

MVP app in `LockMyKeyboard/` — one window, Lock / Unlock, Apple Silicon + macOS 26.
