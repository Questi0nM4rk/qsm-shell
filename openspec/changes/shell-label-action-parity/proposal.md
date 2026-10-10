## Why

A person must be able to mute a sound channel by keyboard or a callable action,
not only by clicking its glyph. `ControlLabel` currently has no keyboard route;
`Slider.actions` exposes level changes but not its existing label operation.
This is the first bounded shell-readiness item under `GOAL.md`.

## What Changes

- Make an optional actionable ControlLabel keyboard-reachable, named for
  accessibility and activatable through one guarded function.
- Expose Slider's label operation as `activateLabel()` and a stable named Action.
- Preserve passive captions, existing sizing and thumb-navigation behavior.
- Host a coherent mute example and requested native-input integration checks.
- Stop at owner review of this one operation; no catalog-wide implementation.

### Non-goals

Desktop services, networking, Workbench redesign, new global shortcuts,
production audio changes, notification-center work and package upgrades.
Desktop adoption belongs to the companion `consume-shell-label-action` change.

## Capabilities

### New Capabilities
- `shell-label-action`: guarded pointer/keyboard/accessibility/API label activation.

### Modified Capabilities
None; the durable OpenSpec catalog is empty. Existing component records remain
the current design source and will be revised before code.

## Impact

ControlLabel, Slider, their records and provider examples, and SoundChannel's
existing composition. The new Slider action is appended, preserving existing
action positions. No dependencies or layout tokens are added.

## Critiques

- Devil's advocate: a key handler is not reachability. Require real Tab/Backtab
  traversal, exact-once activation, cancellation and disabled refusal.
- Future archaeologist: distinguish a label caption from a label action. Record
  stable action identifiers, caller-owned naming and the changed focus contract.
- Scope sniper: do not generalize an action bus or repair unrelated types.
  Keep the item to the optional label operation and its current sound consumer.

All findings are addressed by the design and requirement scenarios; no waivers.
