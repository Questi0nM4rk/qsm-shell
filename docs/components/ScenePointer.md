# ScenePointer

The one hover reader for surfaces; a HoverHandler that belongs on the ancestor of the surfaces so siblings below and above both keep their hover.
states: inside and outside; `inside` is hover now and `position` holds the last reading.
actions: `contains(area)` throws `ScenePointerAreaError` on any area that is not a rectangle or `triangleArea()`, else answers whether the pointer is inside a rectangle or `triangleArea(a, b, c)`; position is never read alone. `inside`, `position` and `contains()` are the pointer contract, so a surface that takes a pointer and a test that supplies one both speak this shape. An optional `source` supplies `inside` and `position` without replacing containment.
pointer: it reads hover and claims nothing; blocking changes neither sibling case, which is why ancestry is the rule.
keyboard: none; it takes no keys and holds no focus.
screen reader: none; it is instrumentation, not content.
size: none; it has no footprint and follows its ancestor.
tokens: none; no Style, Motion or colour roles of its own.
motion: none.
expected: `source: null` reads real hover; an injected `inside`/`position` source uses the same `contains()` implementation. `triangleArea(a, b, c)` and rectangles include their boundary, exclude outside/ghost positions, and reject degenerate triangles. Descendant hover remains independent.
not designed: clicks, gestures or focus; use StateLayer, TapHandler or the host for those.

## UIX audit

Evidence: source-reviewed only. Runtime-exercised: no. Owner-accepted: no. The existing test
`tests/units/tst_ScenePointer.qml` was read, not run. No live geometry, capture or session was used.

### Purpose and consequence

It finishes one task: a surface learns whether the pointer is inside its area without each host
re-deriving containment. If it fails, a popout either never opens from its trigger or closes
while the hand is still travelling toward it. A consumer sees the popout's behaviour, not this type.

### Controls, states, routes

- Controls (unit `controls`): `source` native or injected. Both implemented (`ScenePointer.qml:9`,
  `workbench/units/ScenePointer.qml:44-49`).
- States: `inside` true or false; `source` null or injected. Implemented in `ScenePointer.qml:9-10`.
- Pointer: native hover on the parent item (`HoverHandler`). It claims no events and grabs nothing,
  so wheel and clicks reach the item beneath (`ScenePointer.qml:5`, no `grab` or `blocking` set).
- Keyboard, focus, screen reader: none. The type is not interactive. Keyboard retention for a
  popout is host policy (ADR 0002, decision 1 and consequences). The accessibility criteria are
  a11y-audit's; this record does not rule on them.
- Wheel: not handled here; the wheel passes through.

### Sizes, empty and long content, failure, cancellation

- Sizes: none. The type paints nothing and has no size preset.
- Empty and long content: not applicable.
- Failure: a malformed area throws `ScenePointerAreaError` from `contains()`, checked before the
  pointer is tested. See D1.
- Cancellation: none in this type. The keep-open grace timer belongs to Rollout
  (`Rollout.qml:136-145`), so this type holds no timer, which is correct.

### Visual roles, palette, motion

- Visual roles and palette pairs: none; the type owns no `Style`, `Motion` or colour role.
- Motion: none. Reduced motion: not applicable.
- Token values referenced by consumers, not by this type: `Motion.hoverGrace` is 180
  (`tokens/deep-night.json:75`, `Motion.qml:112-118`).

### Pointer geometry (assumptions marked)

- Input shape, native: the parent item's bounds. In the desktop, the parent is the full-screen
  `PanelWindow` (`EdgeScene.qml:19`), clipped to its input mask (`EdgeScene.qml:365-400`). The
  mask is built from rollout rects; whether it includes the triangular corridor is not confirmed
  (see H2).
- Input shape, unit: 380 x 380 (`Style.controlWidth`, `tokens/deep-night.json:99`; unit lines 18-19).
- Painted size, unit: the card is 190 wide (`controlWidth / 2`, unit line 28) and its height is
  body plus 2 x `space4` (unit line 29), with those values not read here. The ratio of input to
  painted width is 2.0 (380 / 190), and this is the only pointer-facing ratio the unit shows.
- Distance D and width W: not defined by this type; they belong to the consumer's areas. For a
  consumer's corridor, D is the gap from the anchor's far edge to the card's near edge, and
  W is the corridor's width at the point where the hand enters it.
- Width model (stated): containment only, not a click. The target is entered, not aimed at, so
  W is the area's extent along the approach at entry.
- Difficulty: ID = log2(1 + D / W) (the Shannon form of Fitts' index; MacKenzie 1992, assumed
  here as the model). For a triangle whose apex is the entry point, W at the apex is 0, so
  ID diverges: only the apex point itself counts as inside. This is the structural fact, not a
  measurement.
- Dead run at the corridor apex (consumer geometry, BarPopouts.qml:47-50): a pointer leaving the
  anchor at offset |dy| from its midline is outside every area until it has travelled
  r = 2 |dy| (cx - ax) / ch. With |dy| up to ah / 2, r is at most ah (cx - ax) / ch. Assumed
  values only, not from source: ah = 40, cx - ax = 100, ch = 300, so r <= 13.3 px. The 180 ms grace
  (Rollout) absorbs this unless the hand stalls longer than 180 ms (H4).
- Landing tolerance: zero spatial tolerance beyond the inclusive boundary; no hysteresis here.
  Temporal tolerance is Rollout's grace (180 ms).
- Neighbouring interference: each area is tested alone and the consumer ORs them
  (`Rollout.qml:101`, `Rollout.qml:113`), so an overlapping neighbour does not cancel a hit.
  Descendant hover is independent of the ancestor reader (test row 1, source only).
- Label origins and weights (assumptions, not measured): the index is the Shannon form of Fitts;
  any regression constants for movement time are literature values, unused here. No human average
  is claimed.

### Findings

Source-backed defects:

- D1 (medium), fixed (source-reviewed, load-checked; not owner-accepted). `contains()` now accepts only
  `Qt.rect` values and `triangleArea()` results and throws `ScenePointerAreaError` otherwise, even
  while the pointer is outside. Original defect: `ScenePointer.qml:20-22`. A malformed area is treated as a rectangle, and every
  comparison against `undefined` is false, so `contains()` returns false with no error. What a
  person sees: a popout does not open from a trigger whose area was written with a typo (for
  example `w` for `width`), or closes mid-travel, and nothing reports why. Fix: accept only
  `Qt.rect` values and `triangleArea` results, and fail loudly on any other shape with a named
  error. Shared: no.
- D2 (low). `workbench/units/ScenePointer.qml:39-41`. The fixture card carries a `StateLayer`
  (hover and press) and no action, so a press highlight appears on something that does nothing.
  What a person sees in the unit: press feedback that promises an action. Fix: remove the
  StateLayer from the fixture, or make the card's press show the reader's `inside`. Shared: no.

Redesign proposals (taste, not defects):

- Name: `position` reads as the current pointer, but it holds the last reading outside the area
  (`ScenePointer.qml:10`; record line 4). Rename it `lastPosition`, or return the point only while
  `inside`. See source conflict S1.
- Consumers should listen to `onPositionChanged`, not `onPointChanged`. EdgeScene binds the
  inherited native signal (`EdgeScene.qml:423`), which does not follow an injected `source`. No
  production consumer reads `position` alone. The change is in qsm-desktop, outside this audit.

Source conflicts (owner ruling):

- S1: AGENTS.md naming law ("a name that lies is worse than a long name") against this record's
  own description of `position` as holding the last reading (`ScenePointer.qml:10`; record line 4).
  Both are written down; the owner picks the name.

Hypotheses (not measured):

- H1. The native reader sees only its parent's bounds. A consumer whose areas overhang a smaller
  ancestor would lose hover over the overhang. The desktop's full-screen window avoids this; the
  unit does not overhang, so it is not affected.
- H2. The desktop input mask (`EdgeScene.qml:365-400`) may not include the triangular corridor
  (`BarPopouts.qml:47-50`), in which case the native reader is blind in the corridor. Needs a live
  trace in a real window.
- H3. A `HoverHandler` declared directly under a `PanelWindow` (`EdgeScene.qml:421`) rather than
  under its `contentItem` may not receive window-wide hover in Qt 6. Needs a runtime check.
- H4. The corridor dead run in the geometry section, absorbed by the 180 ms grace unless the hand
  stalls. Consumer-owned.

Not examined: the desktop's runtime behaviour, any live window, any capture, the keyboard route
through the host, and the caelestia equivalent. `~/Clonned/caelestia/repo/components/controls/`
has no hover reader to compare with.
