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


# Check the actual source tree immediately before publication. The release script
# edits only the Homebrew cask version/checksum after building, so verify that its
# contents equal those two expected changes rather than excluding it unconditionally.
# Build outputs are ignored by git; all tracked/untracked source inputs must be clean.
verify_release_source_unchanged() {
  local root="$1" source_sha="$2" version="$3" sha="$4"
  local head status base_cask expected_cask cask_path

  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$sha" =~ ^[0-9a-f]{64}$ ]] ||
    { release_error "invalid release version or SHA-256 for final source check"; return 1; }

  head="$(git -C "$root" rev-parse HEAD)" ||
    { release_error "cannot read source HEAD"; return 1; }
  [[ "$head" == "$source_sha" ]] ||
    { release_error "source HEAD changed during release ($head != $source_sha)"; return 1; }

  # Git status checks both the index and worktree and catches untracked inputs.
  # Only the cask is exempt here; its exact expected contents are checked below.
  status="$(git -C "$root" status --porcelain=v1 --untracked-files=all -- . ':(exclude)Casks/lock-my-keyboard.rb')" ||
    { release_error "cannot recheck release source files"; return 1; }
  if [[ -n "$status" ]]; then
    printf '%s\n' "$status" >&2
    release_error "source files changed after preflight; release aborted"
    return 1
  fi

  cask_path="$root/Casks/lock-my-keyboard.rb"
  base_cask="$(git -C "$root" show "$source_sha:Casks/lock-my-keyboard.rb")" ||
    { release_error "cannot read source cask from commit"; return 1; }
  expected_cask="$(printf '%s\n' "$base_cask" | /usr/bin/sed -E \
    -e "s/version \"[^\"]+\"/version \"${version}\"/" \
    -e "s/sha256 \"[^\"]+\"/sha256 \"${sha}\"/")" ||
    { release_error "cannot construct expected release cask"; return 1; }
  [[ -f "$cask_path" && "$(cat "$cask_path")" == "$expected_cask" ]] ||
    { release_error "Homebrew cask differs from expected version/checksum-only update"; return 1; }
}
