# ADR 0002: Single-window SwiftUI desktop app

## Status

Accepted

## Context

An earlier PRD proposed a menu-bar utility with overlays, timers, and multiple release paths. Product direction is now: one simple screen — keyboard image, Lock/Unlock control — no menu-bar complexity.

## Decision

- Build a standard **SwiftUI macOS app** with a single primary window.
- UI composition:
  1. App title / brand: Lock My Keyboard
  2. Keyboard illustration (top)
  3. Primary Lock / Unlock button (below)
  4. Short status text (Idle / Locked / Needs permission)
- No menu-bar-only mode, no multi-window workflow, no preferences window in MVP.
- Window remains interactive while locked so the user can click Unlock with pointer.

## Consequences

- Positive: Obvious mental model; easy to demo; minimal UI state.
- Negative: User must keep the app window reachable (not hidden behind others without a way back). Mitigation: keep window floating / always-on-top while locked (implementation detail in Spec).
- Rejected alternative: Menu-bar accessory app — deferred indefinitely unless product asks again.
