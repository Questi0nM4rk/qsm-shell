# IconButton

A compact, named action for dense shell controls; the caller supplies the glyph and owns the effect.
states: rest, hover, press, focus and disabled; hover and press go through the shared StateLayer (a disc that grows and lifts, then pushes in), focus rings the complete box, disabled blends every painted role through Style.disabled.
actions: pointer click, Space, Return, Enter, the screen reader's Press action and the `actions` entry all call `activate()` and emit `clicked`; callers never synthesize pointer events.
pointer: the whole padded box is the target and reports a pointing hand; a press fires on release inside the box (released 4, 8 and 14 px outside it, nothing fires); the wheel does nothing and propagates.
keyboard: Tab reaches it (a click focuses it without a ring); Space, Return and Enter read as pressed while held and act once on release, and the repeats of a held key (`isAutoRepeat`) neither press nor act: one 0.7 s hold is one `clicked`. Losing focus mid-press cancels it. Escape has no route.
screen reader: Accessible.Button named `accessibleName`, which defaults to the icon name; a caller gives a human name where the glyph alone is ambiguous. Disabled is the platform's disabled state. (The AT-SPI bus was not reachable in the headless slot: role and name are read from the item, not from the bus.)
size: `size` is a Control preset name (xs 24, sm 32, md 40, lg 48): the box is the preset and the glyph is `Style.glyphAlone(box)` (16, 16, 20, 24), so no call site states either; the padding is the rest of the box, and a slot host that reads `padding` as the hit-box overhang gets the right footprint; a consumer adds `xl` through `sizes.IconButton` or `sizes.Control`.
tokens: the Control size table, glyphAlone, text, disabled, Motion, StateLayer and `Style.snap`; no local measurements or colours.
motion: StateLayer's fast press push-in and restrained hover growth, removed or reduced by Style.reducedMotion.
not designed: a label, loading, a toggled state and menus; Capsule, Segmented or a surface-owned row express those. A host that needs a toggle sets `Accessible.checkable` and `Accessible.checked` itself.

## Contract

- Public: `icon`, `size`, `color`, `accessibleName`, `opticalOffset`, `enabled`, `activate()`, `clicked`; `padding` is derived and settable only where a slot needs a different hit-box overhang.
- `opticalOffset` shifts the glyph by a whole number of device pixels; `play` carries its size / 18 by default because its centroid sits left of its box centre.
- An empty or unknown `icon` draws nothing (SvgIcon reports the missing name) and the accessible name is the icon name.
- The unit (`workbench/units/IconButton.qml`) exposes the four sizes, the `check` and `play` glyphs and enabled and disabled; its flow drives the pointer, Space, Enter and the action, and asserts the box and glyph of every size.

## Measured at scale 1.25

| size | box | glyph | hover disc | pressed disc | ring outer, hovered | rest glyph on ground |
| --- | --- | --- | --- | --- | --- | --- |
| xs | 24 | 16 | 25.6 | 22.4 | 35.2 | 15.79:1 |
| sm | 32 | 16 | 33.6 | 30.4 | 43.2 | 15.79:1 |
| md | 40 | 20 | 41.6 | 38.4 | 51.2 | 15.79:1 |
| lg | 48 | 24 | 49.6 | 46.4 | 59.2 | 15.79:1 |

Hover grows the disc 0.8 px per side (one device pixel), a press pulls it in 0.8 px, and the ring keeps 2.4 px of gap and 2.4 px of stroke outside it throughout (md: ring to disc edge 4.8 px rest, hovered and pressed; before 4.8, 4.0 and 5.6). Hovered, the glyph reads 8.03:1 on the disc; the ring is 10.22:1 on the ground. The disc is 1.97:1 on the ground; it is a hover answer, not a boundary. The 24 px xs box meets the 24 px pointer floor of WCAG 2.5.8 at its edge.

The hover zone read from the item tree with a moving pointer (md) is 40 x 40: no halo, no gap. Every size's target passes the 24 px floor (`drive geom target`) and the glyph is centred in its box to 0 px on both axes.
