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

1. `./scripts/release.sh 1.0.0` or Run from Xcode.
2. Grant Accessibility when prompted.
3. Open Notes → **Lock** → type → no characters.
4. **Unlock** → loader appears briefly → typing works.
5. **Lock** → quit app → typing works again.
6. Confirm Help sheet opens.

## Homebrew install check

```bash
brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard
brew install --cask --no-quarantine lock-my-keyboard
xattr -p com.apple.quarantine /Applications/LockMyKeyboard.app || echo "no quarantine (ok)"
open -a LockMyKeyboard
```
