# Lock My Keyboard

A simple macOS app for Apple Silicon that temporarily disables the keyboard so you can clean it without accidental typing.

**Lock → clean → Unlock.** One window. No accounts. No keystroke logging.

## Platform

| | |
| --- | --- |
| CPU | Apple Silicon (`arm64`) only |
| OS | macOS 26+ |
| UI | Single window — keyboard art + Lock/Unlock |

## Install (Homebrew)

```bash
brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard
brew install --cask --no-quarantine lock-my-keyboard
open -a LockMyKeyboard
```

Grant **Accessibility** on first Lock (System Settings → Privacy & Security → Accessibility).

> First releases are unsigned. `--no-quarantine` (and the cask `postflight`) clears Gatekeeper quarantine. Notarization can come later.

## Develop

```bash
open LockMyKeyboard/LockMyKeyboard.xcodeproj
```

### Test

```bash
./scripts/test.sh
```

### Release

```bash
./scripts/release.sh 1.0.0
# then commit the updated Casks/lock-my-keyboard.rb sha256 and push
```

## Docs

- [Testing](docs/TESTING.md)
- [Technical Review](docs/TECHNICAL_REVIEW.md)
- [Spec](docs/SPEC.md)
- [ADRs](docs/adr/)
- [App icon](docs/APP_ICON.md)
- [Changelog](CHANGELOG.md)

## Manual smoke

1. Run the app → **Lock** → grant Accessibility if asked.
2. Type in Notes — nothing should appear.
3. **Unlock** — typing returns (loader may flash briefly).
4. **Lock** → quit — typing returns.
