# IconButton

A compact, named action for dense shell controls; the caller supplies the glyph and owns the effect.
states: rest, hover, press, focus and disabled; hover and press use the shared StateLayer response, focus rings the complete hit target, disabled blends every painted role through Style.disabled.
actions: pointer click, Space, Enter and the `actions` entry all call `activate()` and emit clicked; callers never synthesize pointer events.
pointer: the whole padded body is the target and reports a pointing cursor; wheel does nothing and propagates.
keyboard: T.Control tab focus and activation; focus remains visible until it leaves.
screen reader: Accessible.Button with accessibleName (defaults to icon for a usable fallback; callers provide a human name where the glyph alone is ambiguous).
size: `size` is a Control preset name (xs 24, sm 32, md 40, lg 48): the box is the preset and the glyph is `Style.glyphAlone(box)` (16, 16, 20, 24), so no call site states either; the padding is the rest of the box, and a slot host that reads `padding` as the hit-box overhang gets the right footprint; a consumer adds `xl` through `sizes.IconButton` or `sizes.Control`.
tokens: the Control size table, glyphAlone, text, disabled, accent, Motion and StateLayer; no local measurements or colors.
motion: StateLayer's fast press acknowledgement and restrained hover response, removed or reduced by Style.reducedMotion.
not designed: label-bearing primary buttons, loading, toggled state and menus; Capsule, Segmented or a surface-owned row express those concepts.

## Contract

- Public controls: `icon`, `size`, `color`, `accessibleName`, `enabled`, `activate()`, `clicked`, `opticalOffset`;
  `padding` is derived and settable only where a slot needs a different hit-box overhang.
- All five states are implemented through `StateLayer`. The hover disc and the focus ring are pills.
- Not designed: loading, menu, label-bearing, toggled. A host that needs a toggle sets `Accessible.checkable`
  and `Accessible.checked` itself.
- Routes: the pointer press fires on release inside the bounds and a drag past the threshold cancels; a click
  focuses the control without a ring; Return, Enter and Space call `activate()`; Escape has no route; the
  wheel propagates. Disabled: `activate()` returns without emitting.
- Empty or unknown `icon`: nothing is drawn and the accessible name is empty or the icon name.
- The unit (`workbench/units/IconButton.qml`) exposes the four sizes and enabled and disabled.

## Derived values

| size | box | glyph | padding |
| --- | --- | --- | --- |
| xs | 24 | 16 | 4 |
| sm | 32 | 16 | 8 |
| md | 40 | 20 | 10 |
| lg | 48 | 24 | 12 |

Rest glyph `textMuted` #c5bad1 on `band` is 8.61:1; on `surface` #3b3145 6.61:1. The 24 px box clears the
24 px pointer floor of WCAG 2.5.8 at its edge; whether a smaller visible glyph meets the criterion is
a11y-audit's.
