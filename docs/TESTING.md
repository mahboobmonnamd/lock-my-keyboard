# Testing

## Automated (required before release)

GitHub Actions runs the macOS 26 arm64 Swift tests, Homebrew cask audit, quarantine removal smoke, and offline release-preflight negative tests on pull requests and pushes to main. CI does not validate real Accessibility permissions or actual keyboard interception.

```bash
./scripts/test.sh
bash scripts/test-release-preflight.sh
brew audit --cask --skip-style ./Casks/lock-my-keyboard.rb
```

Covers:

- Lock succeeds when Accessibility is granted (mock service)
- Lock refuses without permission
- Unlock restores idle / calls `stop()`
- Service failures surface as error UI state
- Quit path fail-open (`prepareToQuit`)
- Error equality / user-facing copy

## Manual smoke (before tagging a release)

1. Run from Xcode, or install the release build.
2. Grant Accessibility when prompted.
3. Open Notes → **Lock** → type → no characters. Also press F10 (mute) / volume / brightness — no effect.
4. **Unlock** → loader appears briefly → typing works; media keys work again.
5. **Lock** → quit app → typing works again.
6. **Lock** → revoke Accessibility permission or disable the tap via a debugger → within about a second, the UI must stop showing **Locked** and display a clear warning; typing may be active.
7. Restore Accessibility and retry Lock; confirm it works. Repeat after sleep/wake.
8. Confirm Help sheet opens and force-quitting restores input.

## Homebrew install check

After a release is published and the cask sha256 is on `main`:

```bash
brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard
brew trust --cask mahboobmonnamd/lock-my-keyboard/lock-my-keyboard
brew install --cask lock-my-keyboard

ls /Applications/LockMyKeyboard.app
xattr -p com.apple.quarantine /Applications/LockMyKeyboard.app || echo "No quarantine attribute (unsigned release workaround)"
open -a LockMyKeyboard
```

See [INSTALL.md](./INSTALL.md) for upgrade, uninstall, and troubleshooting.
