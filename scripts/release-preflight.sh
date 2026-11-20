#!/usr/bin/env bash
# Shell functions shared by the release script and its non-publishing regression tests.
# No network writes and no release creation occur here.
#
# Use: source scripts/release-preflight.sh
#      verify_release_preflight ROOT REPO VERSION
#      verify_remote_tag_absent REPO TAG
#      verify_remote_tag_points_to REPO TAG SOURCE_SHA

release_error() {
  printf 'ERROR: %s\n' "$*" >&2
  return 1
}

release_remote_url() {
  local repo="$1"
  if ! [[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    release_error "invalid GitHub repository: $repo"
    return 1
  fi
  printf 'https://github.com/%s.git\n' "$repo"
}

verify_remote_tag_absent() {
  local repo="$1" tag="$2" remote result=0
  remote="$(release_remote_url "$repo")" || return 1

  # --exit-code: 0 = matching tag, 2 = no matching tag, any other code = error.
  # Fail closed on an unreachable remote or authentication problems.
  git ls-remote --exit-code --refs "$remote" "refs/tags/$tag" >/dev/null 2>&1 || result=$?
  case "$result" in
    0) release_error "remote tag $tag already exists in $repo; choose a new version" ;;
    2) return 0 ;;
    *) release_error "cannot verify remote tag $tag (git ls-remote exit $result); refusing to publish" ;;
  esac
}

verify_remote_tag_points_to() {
  local repo="$1" tag="$2" expected="$3" remote refs actual
  remote="$(release_remote_url "$repo")" || return 1
  refs="$(git ls-remote "$remote" "refs/tags/$tag" "refs/tags/$tag^{}")" ||
    { release_error "cannot inspect published tag $tag"; return 1; }

  # Annotated tags have a peeled ^{} ref; lightweight tags have only the direct ref.
  actual="$(printf '%s\n' "$refs" | awk -v ref="refs/tags/$tag^{}" '$2 == ref { print $1 }')"
  if [[ -z "$actual" ]]; then
    actual="$(printf '%s\n' "$refs" | awk -v ref="refs/tags/$tag" '$2 == ref { print $1 }')"
  fi
  [[ -n "$actual" && "$actual" == "$expected" ]] ||
    release_error "published tag $tag is not at source commit $expected (actual: ${actual:-missing})"
}

verify_release_preflight() {
  local root="$1" repo="$2" version="$3" plist_version status tag
  tag="v$version"

  if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    release_error "expected version X.Y.Z"
    return 1
  fi
  plist_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$root/LockMyKeyboard/LockMyKeyboard/Info.plist")" ||
    { release_error "cannot read Info.plist version"; return 1; }
  [[ "$version" == "$plist_version" ]] ||
    { release_error "release $version does not match Info.plist version $plist_version"; return 1; }

  # A release is built only from a clean, committed source tree. Unlike git diff,
  # porcelain includes untracked (non-ignored) app assets and other build inputs.
  status="$(git -C "$root" status --porcelain=v1 --untracked-files=all)" ||
    { release_error "cannot inspect working tree"; return 1; }
  if [[ -n "$status" ]]; then
    printf '%s\n' "$status" >&2
    release_error "working tree has tracked or untracked changes; commit or clean before releasing"
    return 1
  fi

  if git -C "$root" show-ref --verify --quiet "refs/tags/$tag"; then
    release_error "local tag $tag already exists; choose a new version"
    return 1
  fi
  verify_remote_tag_absent "$repo" "$tag"
}
