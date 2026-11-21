#!/usr/bin/env bash
# Offline regression tests for version/source/tag integrity. Never publishes a release.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/release-preflight.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
WORK="$TMP/work"
REMOTE="$TMP/remote.git"
REPO="mahboobmonnamd/lock-my-keyboard"
VERSION="1.0.1"
TAG="v$VERSION"

git init -q --bare "$REMOTE"
git init -q "$WORK"
git -C "$WORK" config user.email "test@example.invalid"
git -C "$WORK" config user.name "Release Preflight Test"
mkdir -p "$WORK/LockMyKeyboard/LockMyKeyboard" "$WORK/Casks"
cat > "$WORK/Casks/lock-my-keyboard.rb" <<'EOF'
cask "lock-my-keyboard" do
  version "1.0.1"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
end
EOF
cp "$ROOT/LockMyKeyboard/LockMyKeyboard/Info.plist" "$WORK/LockMyKeyboard/LockMyKeyboard/Info.plist"
printf 'tracked\n' > "$WORK/tracked.txt"
git -C "$WORK" add .
git -C "$WORK" commit -qm "fixture"
SOURCE_SHA="$(git -C "$WORK" rev-parse HEAD)"

# Redirect only this repository's HTTPS remote to a throwaway local bare repository.
# Neither the test nor the release preflight needs live GitHub access.
export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
git config --file "$GIT_CONFIG_GLOBAL" "url.file://$REMOTE.insteadOf" "https://github.com/$REPO.git"

count=0
ok() { count=$((count + 1)); printf 'PASS %s\n' "$1"; }
expect_fail() {
  local case_name="$1"
  shift
  if "$@" > "$TMP/command.log" 2>&1; then
    printf 'FAIL %s: unexpected success\n' "$case_name" >&2
    exit 1
  fi
  ok "$case_name"
}

verify_release_preflight "$WORK" "$REPO" "$VERSION"
ok "clean committed tree with absent remote tag is accepted"
expect_fail "wrong bundle version" verify_release_preflight "$WORK" "$REPO" "1.0.2"

printf 'untracked\n' > "$WORK/unknown-asset.txt"
expect_fail "untracked files block release" verify_release_preflight "$WORK" "$REPO" "$VERSION"
rm "$WORK/unknown-asset.txt"

printf 'dirty\n' >> "$WORK/tracked.txt"
expect_fail "modified tracked file blocks release" verify_release_preflight "$WORK" "$REPO" "$VERSION"
git -C "$WORK" checkout -q -- tracked.txt

printf 'staged\n' > "$WORK/staged.txt"
git -C "$WORK" add staged.txt
expect_fail "staged changes block release" verify_release_preflight "$WORK" "$REPO" "$VERSION"
git -C "$WORK" reset -q -- staged.txt
rm "$WORK/staged.txt"

git -C "$WORK" tag "$TAG"
expect_fail "local tag blocks release" verify_release_preflight "$WORK" "$REPO" "$VERSION"
git -C "$WORK" push -q "$REMOTE" "refs/tags/$TAG"
git -C "$WORK" tag -d "$TAG" >/dev/null
expect_fail "remote tag without a GitHub Release blocks release" verify_release_preflight "$WORK" "$REPO" "$VERSION"
verify_remote_tag_points_to "$REPO" "$TAG" "$SOURCE_SHA"
ok "published lightweight tag resolves to the source SHA"
expect_fail "wrong published source SHA is rejected" verify_remote_tag_points_to "$REPO" "$TAG" "0000000000000000000000000000000000000000"

git -C "$WORK" push -q "$REMOTE" ":refs/tags/$TAG"
git -C "$WORK" tag -a "$TAG" -m "annotated fixture"
git -C "$WORK" push -q "$REMOTE" "refs/tags/$TAG"
verify_remote_tag_points_to "$REPO" "$TAG" "$SOURCE_SHA"
ok "published annotated tag resolves to peeled source SHA"
git -C "$WORK" push -q "$REMOTE" ":refs/tags/$TAG"
git -C "$WORK" tag -d "$TAG" >/dev/null

mv "$REMOTE" "$TMP/remote-unreachable.git"
expect_fail "unreachable remote fails closed" verify_release_preflight "$WORK" "$REPO" "$VERSION"
mv "$TMP/remote-unreachable.git" "$REMOTE"



# Final source verification runs *after* updating the cask and just before
# publishing. Its only allowed change is the exact version/sha256 cask rewrite.
RELEASE_SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
cat > "$WORK/Casks/lock-my-keyboard.rb" <<EOF
cask "lock-my-keyboard" do
  version "$VERSION"
  sha256 "$RELEASE_SHA"
end
EOF
cp "$WORK/Casks/lock-my-keyboard.rb" "$TMP/expected-cask"
verify_release_source_unchanged "$WORK" "$SOURCE_SHA" "$VERSION" "$RELEASE_SHA"
ok "final check allows only expected cask checksum update"

printf 'late edit\n' >> "$WORK/tracked.txt"
expect_fail "source modified after preflight blocks publishing" verify_release_source_unchanged "$WORK" "$SOURCE_SHA" "$VERSION" "$RELEASE_SHA"
git -C "$WORK" checkout -q -- tracked.txt

printf 'late asset\n' > "$WORK/late-untracked-resource.txt"
expect_fail "new source asset after preflight blocks publishing" verify_release_source_unchanged "$WORK" "$SOURCE_SHA" "$VERSION" "$RELEASE_SHA"
rm "$WORK/late-untracked-resource.txt"

printf 'late staged asset\n' > "$WORK/late-staged-resource.txt"
git -C "$WORK" add late-staged-resource.txt
expect_fail "staged source after preflight blocks publishing" verify_release_source_unchanged "$WORK" "$SOURCE_SHA" "$VERSION" "$RELEASE_SHA"
git -C "$WORK" reset -q -- late-staged-resource.txt
rm "$WORK/late-staged-resource.txt"

printf '# unapproved cask change\n' >> "$WORK/Casks/lock-my-keyboard.rb"
expect_fail "unexpected cask change after preflight blocks publishing" verify_release_source_unchanged "$WORK" "$SOURCE_SHA" "$VERSION" "$RELEASE_SHA"
cp "$TMP/expected-cask" "$WORK/Casks/lock-my-keyboard.rb"

git -C "$WORK" commit -q --allow-empty -m "changed head after build"
expect_fail "new HEAD after preflight blocks publishing" verify_release_source_unchanged "$WORK" "$SOURCE_SHA" "$VERSION" "$RELEASE_SHA"

printf 'Release preflight: %s cases passed\n' "$count"
