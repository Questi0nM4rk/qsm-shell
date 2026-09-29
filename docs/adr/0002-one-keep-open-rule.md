# ADR 0002: One keep-open rule, owned by the component

## Context

`Rollout` already reports `triggered`, `hovered`, `keepOpen`, `wantsOpen`,
`closeDelay` and a `hoverAreas` list, and refuses to close itself. The rail
answered anyway: `BarPopouts` sets only `triggerAreas`, and `EdgeScene` re-derives
the union — rail band, anchor, card, every open descendant, the travel
triangle — plus two `hoverGrace` timers and a `keyboardGrab` guard. That is
`hoverAreas` plus `closeDelay`, hand-written, for two nesting levels. A third
copy then landed in a Workbench adapter, where a passing flow tested the copy.

`hoverAreas` takes rectangles, so the triangle could not be expressed where it
stood. The failure was not that the component was wrong; it was that the answer
had nowhere to go.

## Decision

1. A surface supplies areas; it never re-derives the union, the grace period or
   the close. A corridor needing a diagonal becomes a named area type here.
2. `Rollout` stops deriving size from `inner.childrenRect`. caelestia's
   `ButtonBase` makes `implicitWidth` `required` so an unsized control is a
   compile error; an empty rollout measuring zero is the same defect.
3. A pointer is an injection point: `ScenePointer`'s `inside`, `position` and
   `contains()` are the contract, and a test supplies an object with that shape.
4. `StateLayer` gains caelestia's `manualHoverOverride` / `manualPressOverride`,
   so "open, therefore lit" is two booleans rather than a geometric union.

## Consequences

`EdgeScene`'s region test moves into a provider-owned type that takes a
pointer, and the workbench passes its mock to that same type. Same regions,
same 180 ms, same `keyboardGrab` exception — one owner. caelestia's
`TransformWatcher` replaces three `mapToItem`-in-a-binding call sites that are
currently defended by long comments.
