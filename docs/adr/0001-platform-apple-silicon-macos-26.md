# ADR 0001: Apple Silicon + macOS 26 only

## Status

Accepted

## Context

We want the smallest possible maintenance surface for Lock My Keyboard. Supporting Intel Macs, older macOS releases, or dual architectures forces conditional code, extra CI, and more permission/event-tap edge cases.

The development machine is already Apple Silicon on macOS 26.x with Xcode 26.

## Decision

- Ship **arm64-only** binaries (no `x86_64`, no universal binary requirement for MVP).
- Support **macOS 26** as the sole deployment target (`MACOSX_DEPLOYMENT_TARGET=26.0`).
- Do not add runtime OS-version branching in MVP.

## Consequences

- Positive: One toolchain, one test matrix, simpler event-tap assumptions.
- Negative: Users on older macOS or Intel cannot run the app.
- Follow-up: If demand appears later, a new ADR can raise/widen support deliberately.
