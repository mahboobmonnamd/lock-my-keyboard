# Install Lock My Keyboard

**Yes — v1.0.0 is released.** You can install it with Homebrew from this repo’s cask.

Release: https://github.com/mahboobmonnamd/lock-my-keyboard/releases/tag/v1.0.0

## Requirements

- Apple Silicon Mac (`arm64`)
- macOS 26+
- [Homebrew](https://brew.sh)

## Install with Homebrew

```bash
brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard
brew install --cask lock-my-keyboard
open -a LockMyKeyboard
```

### What this does

1. Taps this GitHub repo (cask lives in `Casks/lock-my-keyboard.rb`).
2. Downloads `LockMyKeyboard-1.0.0.zip` from the GitHub Release.
3. Installs `LockMyKeyboard.app` into `/Applications`.
4. Clears quarantine attributes in a cask `postflight` (`xattr -cr`) so an unsigned first release can open without Gatekeeper friction.

> Homebrew removed the `--no-quarantine` flag. We clear quarantine in the cask itself for now. Notarization can replace this later.

### First launch

1. Open **Lock My Keyboard**.
2. Click **Lock**.
3. When macOS asks, enable the app under  
   **System Settings → Privacy & Security → Accessibility**.
4. Click **Lock** again, then clean; click **Unlock** when done.

### Upgrade

```bash
brew update
brew upgrade --cask lock-my-keyboard
```

### Uninstall

```bash
brew uninstall --cask lock-my-keyboard
# optional full cleanup:
brew zap --cask lock-my-keyboard
```

## Install from the release zip (without Homebrew)

```bash
# download from:
# https://github.com/mahboobmonnamd/lock-my-keyboard/releases/tag/v1.0.0

unzip LockMyKeyboard-1.0.0.zip
xattr -cr LockMyKeyboard.app
mv LockMyKeyboard.app /Applications/
open -a LockMyKeyboard
```

## Verify install

```bash
ls /Applications/LockMyKeyboard.app
xattr -p com.apple.quarantine /Applications/LockMyKeyboard.app || echo "no quarantine (ok)"
open -a LockMyKeyboard
```

## Troubleshooting

| Issue | Fix |
| --- | --- |
| `brew tap` permission / Cellar not writable | `sudo chown -R "$(whoami)" /opt/homebrew` then retry |
| App blocked by macOS | `xattr -cr /Applications/LockMyKeyboard.app` then open again |
| Lock does nothing | Grant Accessibility for **Lock My Keyboard**, quit and reopen the app |
| Wrong Mac | Apple Silicon + macOS 26 only |

## Maintainer: cut a new release

```bash
./scripts/test.sh
./scripts/release.sh 1.0.1
# commit updated Casks/lock-my-keyboard.rb (sha256), push main
```

See also [TESTING.md](./TESTING.md) and [CHANGELOG.md](../CHANGELOG.md).
