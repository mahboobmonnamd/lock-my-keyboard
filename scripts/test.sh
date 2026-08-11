#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/LockMyKeyboard/LockMyKeyboard.xcodeproj"
DERIVED="$ROOT/LockMyKeyboard/DerivedData"

echo "==> Running LockMyKeyboard unit tests (macOS arm64)"
xcodebuild \
  -project "$PROJECT" \
  -scheme LockMyKeyboard \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED" \
  test

echo "==> Tests passed"
