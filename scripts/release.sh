#!/usr/bin/env bash
# Build, test, package, publish GitHub release, and refresh the Homebrew cask.
# First release / unsigned: strips quarantine (no notarization).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/LockMyKeyboard/LockMyKeyboard.xcodeproj"
DERIVED="$ROOT/dist/DerivedData"
DIST="$ROOT/dist"
CASK="$ROOT/Casks/lock-my-keyboard.rb"
REPO="${GITHUB_REPOSITORY:-mahboobmonnamd/lock-my-keyboard}"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    "$ROOT/LockMyKeyboard/LockMyKeyboard/Info.plist" 2>/dev/null || true)"
fi
if [[ -z "$VERSION" ]]; then
  VERSION="1.0.0"
fi

TAG="v${VERSION}"
APP_NAME="LockMyKeyboard"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
APP_PATH="$DERIVED/Build/Products/Release/${APP_NAME}.app"
ZIP_PATH="$DIST/$ZIP_NAME"

echo "==> Release ${TAG} (${REPO})"

command -v xcodebuild >/dev/null
command -v gh >/dev/null
command -v brew >/dev/null

echo "==> 1/6 Tests"
bash "$ROOT/scripts/test.sh"

echo "==> 2/6 Release build (arm64)"
rm -rf "$DERIVED"
mkdir -p "$DIST"
xcodebuild \
  -project "$PROJECT" \
  -scheme LockMyKeyboard \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED" \
  clean build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_HARDENED_RUNTIME=NO

test -d "$APP_PATH"

echo "==> 3/6 Clear quarantine attributes"
/usr/bin/xattr -cr "$APP_PATH" || true

echo "==> 4/6 Package ${ZIP_NAME}"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
/usr/bin/xattr -cr "$ZIP_PATH" || true
SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
echo "    sha256: ${SHA}"
echo "$SHA  ${ZIP_NAME}" > "$DIST/${ZIP_NAME}.sha256"

echo "==> 5/6 Update Homebrew cask"
if [[ -f "$CASK" ]]; then
  /usr/bin/sed -i '' -E "s/version \"[^\"]+\"/version \"${VERSION}\"/" "$CASK"
  /usr/bin/sed -i '' -E "s/sha256 \"[^\"]+\"/sha256 \"${SHA}\"/" "$CASK"
  echo "    updated ${CASK}"
else
  echo "    WARN: missing ${CASK}"
fi

echo "==> 6/6 GitHub release ${TAG}"
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "    release ${TAG} exists — uploading assets"
  gh release upload "$TAG" "$ZIP_PATH" "$DIST/${ZIP_NAME}.sha256" --repo "$REPO" --clobber
else
  gh release create "$TAG" "$ZIP_PATH" "$DIST/${ZIP_NAME}.sha256" \
    --repo "$REPO" \
    --title "Lock My Keyboard ${VERSION}" \
    --notes "$(cat <<EOF
## Lock My Keyboard ${VERSION}

First public release — Apple Silicon (arm64), macOS 26.

### Install with Homebrew

\`\`\`bash
brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard
brew install --cask lock-my-keyboard
open -a LockMyKeyboard
\`\`\`

Or download \`${ZIP_NAME}\`, unzip, then:

\`\`\`bash
xattr -cr LockMyKeyboard.app
open LockMyKeyboard.app
\`\`\`

Grant **Accessibility** on first Lock. Full guide: docs/INSTALL.md

### Notes
- Unsigned / not notarized (cask postflight clears quarantine).
- No keystroke logging. Pointer stays active while locked.
EOF
)"
fi

echo ""
echo "Done."
echo "  zip:    ${ZIP_PATH}"
echo "  sha256: ${SHA}"
echo "  tag:    ${TAG}"
echo ""
echo "Commit the updated cask if SHA/version changed, then:"
echo "  brew tap mahboobmonnamd/lock-my-keyboard https://github.com/mahboobmonnamd/lock-my-keyboard"
echo "  brew install --cask lock-my-keyboard"
echo "Docs: docs/INSTALL.md"
