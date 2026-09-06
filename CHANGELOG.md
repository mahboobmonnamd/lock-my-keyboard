# Changelog

## 1.0.1 — 2026-09-06

### Fixed
- Media and top-row function keys (mute, volume, brightness, play/pause) are now blocked while locked — they previously passed through as system-defined events

## 1.0.0 — 2026-08-11

### Added
- One-window Lock My Keyboard app for Apple Silicon / macOS 26
- CGEvent-tap keyboard lock with pointer-only Unlock
- Accessibility onboarding and Help sheet
- Busy loader while locking / unlocking
- Unit tests, `scripts/test.sh`, `scripts/release.sh`
- Homebrew cask with quarantine cleared on install
