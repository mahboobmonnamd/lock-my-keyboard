# Testing

## Automated (required before release)

```bash
./scripts/test.sh
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
3. Open Notes → **Lock** → type → no characters.
4. **Unlock** → loader appears briefly → typing works.
5. **Lock** → quit app → typing works again.
6. Confirm Help sheet opens.

## Homebrew install check

After a release is published and the cask sha256 is on `main`:

```bash
brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard
brew trust mahboobmonnamd/lock-my-keyboard
brew install --cask lock-my-keyboard

ls /Applications/LockMyKeyboard.app
xattr -p com.apple.quarantine /Applications/LockMyKeyboard.app || echo "no quarantine (ok)"
open -a LockMyKeyboard
```

See [INSTALL.md](./INSTALL.md) for upgrade, uninstall, and troubleshooting.
