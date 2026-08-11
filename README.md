# Lock My Keyboard

A simple macOS app for Apple Silicon that temporarily disables the keyboard so you can clean it without accidental typing.

**Lock → clean → Unlock.** One window. No accounts. No keystroke logging.

## Platform

| | |
| --- | --- |
| CPU | Apple Silicon (`arm64`) only |
| OS | macOS 26+ |
| UI | Single window — keyboard art + Lock/Unlock |

## Install with Homebrew

**v1.0.0 is released** — you can install via brew:

```bash
brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard
brew trust mahboobmonnamd/lock-my-keyboard
brew install --cask lock-my-keyboard
open -a LockMyKeyboard
```

`brew trust` is required once for this third-party tap. Then grant **Accessibility** on first Lock  
(System Settings → Privacy & Security → Accessibility).

Full steps, zip install, upgrade/uninstall, and troubleshooting: **[docs/INSTALL.md](docs/INSTALL.md)**

Release page: https://github.com/mahboobmonnamd/lock-my-keyboard/releases/tag/v1.0.0

> First releases are unsigned. The cask clears quarantine with `xattr` after install (Homebrew no longer supports `--no-quarantine`).

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
./scripts/release.sh 1.0.1
# commit updated Casks/lock-my-keyboard.rb sha256, then push
```

## Docs

- [Install](docs/INSTALL.md)
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
