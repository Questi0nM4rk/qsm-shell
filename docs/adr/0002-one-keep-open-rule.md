# ADR 0002: One keep-open rule, owned by the component

## Context

Region union and grace are component mechanisms; keyboard retention and the
consequence of dismissal are surface policy. Keeping geometry in both a live
surface and its provider makes a passing provider flow prove the copy instead
of the component. Nested placement, triangular travel corridors and injected
pointer facts must therefore participate in the same library implementation.

## Decision

1. A surface supplies areas and answers `keepOpen`; it never re-derives the
   union or grace period. `ScenePointer.triangleArea(a, b, c)` creates a named,
   data-only area accepted by `contains()` alongside rectangles. Degenerate
   triangles contain nothing. Rollout includes its open descendant's hover
   verdict; the host does not walk descendants to rebuild their geometry.
2. `Rollout.bodyWidth` and `bodyHeight` are required, owner-supplied dimensions;
   the component never derives them from `inner.childrenRect`. An unsized
   caller fails to construct instead of silently measuring zero.
3. A pointer is an injection point: `ScenePointer.source` optionally supplies
   `inside` and `position`; null reads real input. `contains()` remains the one
   implementation, so a fixture cannot replace geometry with its own answer.
4. `StateLayer` gains caelestia's `manualHoverOverride` / `manualPressOverride`,
    so "open, therefore lit" is two booleans rather than a geometric union.
   Overrides supply visual state only: disabled still gates them and they do
   not fabricate clicks or pointer-enter selection intent.

## Consequences

`EdgeScene` and the Workbench adapter provide rail, anchor and corridor areas
to their real `BarPopouts`; both read the inherited Rollout `keepOpen` fact.
The component owns the grace timer, including a newly shown body outside all
areas. Keyboard retention remains host policy; release re-evaluates the
component fact immediately. A shared source must preserve hover on descendants.

## Acceptance

- Production and provider contain no triangle predicate, union predicate or
  popout grace timer. Their dismissal route reads `keepOpen` and host policy.
- Real pointer and injected source drive the same containment implementation;
  rectangle, diagonal corridor, boundary, outside and degenerate cases work.
- Parent, child and deeper nesting stay open through travel, close after grace,
  and do not close while the host retains keyboard ownership. Suppression and
  teardown stop pending grace.
- Manual StateLayer state never triggers an action; real pointer entry still
  reports selection intent even while a host holds visual hover.
- Native events, desktop flows and a live nested trace verify these facts;
  no fake pointer position or pixel assertion substitutes for them.
