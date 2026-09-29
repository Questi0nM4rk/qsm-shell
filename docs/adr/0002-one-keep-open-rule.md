# ADR 0002: One keep-open rule, owned by the component

## Context

`Rollout` already reports the whole keep-open vocabulary: `triggered`,
`hovered`, `keepOpen`, `wantsOpen`, `closeDelay` and a `hoverAreas` list. It
refuses to close itself, by its own documented choice — the surface holding it
decides what `keepOpen` means.

The rail rollout then answered the question a second time. `BarPopouts` sets
only `triggerAreas`, leaves `hoverAreas` empty, and `EdgeScene` re-derives the
rule on its own: the rail band, the anchor cell, the card, every open
descendant, and the travel triangle between them, plus two
`Motion.hoverGrace` close timers and a `keyboardGrab` guard. That is
`hoverAreas` plus `closeDelay`, written by hand, for two nesting levels.

`Rollout.hoverAreas` takes rectangles, so the travel triangle genuinely cannot
be expressed where it stands. The failure was not that the component was
wrong; it was that the answer had no place to go, and the next need re-derived
the nearest thing it could. A third copy then landed in the `qsm-desktop`
Workbench adapter, where a passing dismissal flow tested the re-derivation
rather than the rail.

caelestia never reaches this. Its `StateLayer` carries `manualHoverOverride`
and `manualPressOverride`, so an external owner asserts a state INTO the layer
(`PopupRow.qml`: a row stays lit while its popup is open, after the pointer
left the row), and its one screen-level hit tester decides every panel's
open/close in a single place. Two mechanisms, both cheap. We built the better
container and left the host to do the work.

## Decision

1. **The keep-open rule has one implementation and it is not the host's.** A
   surface supplies AREAS; it never re-derives the union, the grace period or
   the close. `Rollout.hoverAreas` grows the shapes `triggerAreas` already
   allows — rectangles today, and a corridor that needs a diagonal becomes a
   named area type rather than a second predicate in a scene.
2. **`Rollout` reports what a host needs to act, and a host may also assert
   state into a surface.** `StateLayer` gains `manualHoverOverride` and
   `manualPressOverride` from caelestia, so "this entry is open, therefore lit"
   is two booleans instead of a geometric union.
3. **A pointer is an injection point.** `ScenePointer`'s `inside`, `position`
   and `contains()` are the pointer contract. Anything that needs a pointer a
   test cannot produce — the Workbench mock — supplies an object with that
   shape. `ScenePointer` gains a way to be overridden so the same test runs
   live and under flow; no consumer re-implements the geometry.
4. **A host that finds itself re-deriving a rule reports that as a component
   gap**, in `docs/BACKLOG.md`, and does not ship the re-derivation meanwhile
   unless the component genuinely cannot express it. A copy that cannot say
   what it is for does not ship at all.

## Consequences

- `EdgeScene`'s region test moves out into a provider-owned type that takes a
  pointer, and the Workbench adapter passes the mock to the same type. The
  duplication disappears rather than being documented.
- `Rollout` stops deriving its size from `inner.childrenRect`. caelestia's
  `ButtonBase` makes `implicitWidth`/`implicitHeight` `required` precisely so
  an unsized control is a compile error; an empty rollout that silently
  measures zero is the same defect.
- `mapToItem` in a binding is not reactive. caelestia solves it with
  `TransformWatcher`; three call sites here defend it with long comments. The
  type is adopted and the comments go.
- Existing consumer behaviour is preserved through the change: same regions,
  same 180 ms, same `keyboardGrab` exception — now with one owner.
