# Install Lock My Keyboard

**Yes — v1.0.1 is released.** You can install it with Homebrew from this repo’s cask.

Release: https://github.com/mahboobmonnamd/lock-my-keyboard/releases/tag/v1.0.1

## Requirements

- Apple Silicon Mac (`arm64`)
- macOS 26+
- [Homebrew](https://brew.sh)

## Install with Homebrew

Third-party taps are untrusted by default. Trust only this specific cask, then install:

```bash
brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard
brew trust --cask mahboobmonnamd/lock-my-keyboard/lock-my-keyboard
brew install --cask lock-my-keyboard
open -a LockMyKeyboard
```

If you already tapped and saw `Refusing to load cask … from untrusted tap`, run:

```bash
brew trust --cask mahboobmonnamd/lock-my-keyboard/lock-my-keyboard
brew install --cask lock-my-keyboard
```

### What this does

1. Taps this GitHub repo (cask lives in `Casks/lock-my-keyboard.rb`).
2. Trusts only this cask, not all packages in the tap.
3. Downloads `LockMyKeyboard-1.0.1.zip` from the GitHub Release.
4. Installs `LockMyKeyboard.app` into `/Applications`.
5. Removes the quarantine attribute for this app only in `postflight_steps` (`xattr -dr com.apple.quarantine`). A genuine failure aborts installation instead of being silently ignored.

> **Unsigned distribution limitation:** Homebrew's postflight clears quarantine to permit launching without Apple Developer ID. This bypasses Gatekeeper's normal origin verification; it is not a security validation. Install only if you trust this repository and verify the release checksum. Signing/notarization remains deferred due to cost.

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
# Download the zip and its .sha256 file from:
# https://github.com/mahboobmonnamd/lock-my-keyboard/releases/tag/v1.0.1
shasum -a 256 -c LockMyKeyboard-1.0.1.zip.sha256

unzip LockMyKeyboard-1.0.1.zip
xattr -dr com.apple.quarantine LockMyKeyboard.app
mv LockMyKeyboard.app /Applications/
open -a LockMyKeyboard
```

## Verify install

```bash
ls /Applications/LockMyKeyboard.app
xattr -p com.apple.quarantine /Applications/LockMyKeyboard.app || echo "No quarantine attribute (expected for unsigned workaround; not a security check)"
open -a LockMyKeyboard
```

## Troubleshooting

| Issue | Fix |
| --- | --- |
| `Refusing to load cask … from untrusted tap` | `brew trust --cask mahboobmonnamd/lock-my-keyboard/lock-my-keyboard` then `brew install --cask lock-my-keyboard` |
| `brew tap` permission / Cellar not writable | Run `brew doctor` and follow Homebrew's targeted ownership guidance; do **not** recursively change `/opt/homebrew` ownership |
| App blocked by macOS | Confirm the download source and SHA-256 first. If proceeding with this unsigned release, remove only `com.apple.quarantine` using `xattr -dr com.apple.quarantine /Applications/LockMyKeyboard.app` |
| Lock does nothing | Grant Accessibility for **Lock My Keyboard**, quit and reopen the app |
| Wrong Mac | Apple Silicon + macOS 26 only |

## Maintainer: cut a new release

```bash
./scripts/test.sh
# First set CFBundleShortVersionString to 1.0.2 in Info.plist and commit.
# Push the source commit before publishing so the release tag can target it.
./scripts/release.sh 1.0.2
# Then commit the updated Casks/lock-my-keyboard.rb checksum and push main.
# The script rejects tracked/untracked changes, existing local/remote tags and
# unreachable tag lookup, and verifies the published tag points at the source SHA.
```

See also [TESTING.md](./TESTING.md) and [CHANGELOG.md](../CHANGELOG.md).
