# ADR 0003: Keyboard lock via CGEvent tap

## Status

Accepted (pending spike confirmation)

## Context

macOS does not provide a public “disable keyboard for cleaning” API. Common approaches:

1. **CGEvent tap** (`CGEvent.tapCreate`) — filter keyboard events at HID/session level.
2. IOKit HID user clients — heavier, more privileged, poor fit for a consumer utility.
3. Accessibility APIs that synthesize events — do not block hardware keys.

We need suppress-while-locked, pointer still works, fail-open on quit.

## Decision

- Use a **listen-and-filter CGEvent tap** on keyboard-related event types (`keyDown`, `keyUp`, `flagsChanged`) while state is Locked.
- Pass through all pointer/scroll events.
- Install tap only after Accessibility permission is confirmed; refuse Lock otherwise.
- On Unlock, Quit, or deinit: disable/release the tap immediately (**fail open**).
- Never log, store, or transmit key codes or characters.

## Consequences

- Positive: Matches product need with modest code; well-known permission model.
- Negative: Requires Accessibility trust; Secure Input / some system shortcuts may behave differently; must be verified on macOS 26 in the spike.
- Spike gate: See Technical Review §5. If spike fails, reopen this ADR before implementation.
