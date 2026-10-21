# Checkbox

A boolean that is a STATEMENT, not an action: something else acts on it later; if throwing it takes effect immediately, it is a Switch.
states: rest hover(box grows 1.15) press(box shrinks 0.88) focus(ring a half step, 2 px, outside the box, radiusXs, box only) disabled(every role through Style.disabled, never opacity) off/on/indeterminate(some but not all, outranks checked)
actions: Toggle (pointer click, Space, Return and `flip()` share it); the host owns `checked` and `indeterminate` and answers `toggleRequested(checked)`
screen reader: indeterminate reports the mixed state, not checked; press and toggle actions share `flip()` and respect disabled without writing host state.
size: `size` is a preset name resolved by Style.size("Checkbox", name) into `boxSize` (sm 12 / md 16 / lg 24, escape hatch); the mark scales WITH the box (check at 3:4, dash at half), the row gap through rhythm(box/2); radiusXs, the 1px border and the ring gap constant; `sizeScale` = box / md for a host composing around it
content: the default slot is an adjacent label (or anything), clipped, a constant `labelWidth` (Style.controlWidth scaled) wide; the host binds its label's width to the slot so a long label elides; the component never renders its own label; the host colours it for disabled
hit area: the row plus a square of at least Style.iconLg around the box (`containmentMask`); natural size does not change
tokens: boxSize textMuted accent textOnPrimary radiusXs spaceTight
colours: off = transparent fill, textMuted border; on = solid accent fill, textOnPrimary mark (a toggle with its own fill is selected as solid accent); indeterminate = accent fill, textOnPrimary dash; disabled = every role through Style.disabled
motion: fill Motion.micro; box growth/press through StateLayer
events: toggleRequested(bool checked) on every route; nothing else
base: T.AbstractButton with checkable false. Measured: a template checkbox writes `checked` itself on click and a tristate one cycles all three states; Space is the template's click, Return and the pointer route call `flip()`
not designed: a tri-state cycle (the host decides what clicking "some" means), drag

## UIX audit

Evidence: source-reviewed only. No Workbench session, capture, pixel sample, accessibility tree or
pointer trace was taken. Colour numbers are token values from `tokens/deep-night.json` and the
`Style` functions, not rendered pixels. Geometry is arithmetic on the source values, not a read of
the live item tree. Only the `deep-night` theme exists in the tokens, so theme parity is not examined.
Keyboard, focus, names and the screen reader are a11y-audit's verdict; they appear here only as
hypotheses.

### Purpose and consequence

It finishes a statement of selection: a host later reads `checked` and acts on it. The host owns
`checked` and `indeterminate`; the component emits `toggleRequested` and writes no state. A control
that takes effect at once is a `Switch`.

### Controls, states, routes

- Public controls: `size` (sm, md, lg), `boxSize` (escape hatch), `indeterminate`, `accentColor`,
  `accessibleName`, `enabled`, the default label slot, `flip()`, `sizeScale`, `toggleRequested(bool)`.
  All are declared (Checkbox.qml:31-45).
- States implemented: off, on, some (`_marked`, Checkbox.qml:71, lets indeterminate outrank checked),
  enabled and disabled. Rest, hover, press and focus come from `StateLayer` (Checkbox.qml:150-160).
- Pointer: the whole row is the template click (Checkbox.qml:76), so the label toggles too. Hover is
  read from the host (`stateLayer.hovered`). Press changes colour only, because `pressScale` stays 1.
- Keyboard: Space is the template click; Return calls `flip()` (Checkbox.qml:77). Keypad Enter is
  not declared (Hypotheses).
- Wheel: no handler declared.
- Focus: `activeFocusOnTab: enabled` (Checkbox.qml:59); the ring is drawn by `StateLayer` only while
  `visualFocus` is set.
- Accessibility declarations: Checkbox.qml:61-67 (role, checkable, checked, mixed, name, press and
  toggle actions). Their criteria are a11y-audit's.
- Failure and cancellation: `flip()` does nothing when disabled (Checkbox.qml:49-51). When the host
  ignores `toggleRequested`, the box keeps its old state, by design. A release outside the row is the
  template's cancel; not measured.
- Not designed: a tri-state cycle, drag, wheel.

### Sizes, empty and long content

- Box: sm 12, md 16, lg 24 (`tokens/deep-night.json` `sizes.Checkbox`, mirrored in `Tokens.qml`).
- Mark: check at 0.75 of the box (sm 9, md 12, lg 18), Checkbox.qml:70 and :116. Dash: box / 2 wide,
  2 px tall at every size (Checkbox.qml:127-128).
- Row gap: `rhythm(box / 2)` = sm 8, md 8, lg 12 (Checkbox.qml:82).
- Bare (no slot content): no gap and no label width, so the input is the box: 12, 16, 24 square.
  Source-reviewed; the unit cannot show it, because any slot child counts as a label.
- Long label: natural width is box + gap + `labelWidth`, a constant; the host-bound label elides in the
  clipped slot.
- Labelled height: max(box, label line). The label line height is not measured (see Not examined).

### Visual roles and pairs (token values)

Non-text contrast, WCAG 1.4.11 (3:1), computed from the token hexes. The host surface is not known,
so three plausible hosts are used.

| pair | ratio | against |
| --- | --- | --- |
| textMuted border on band | 8.61 | 3 |
| textMuted border on surface | 6.61 | 3 |
| textMuted border on overlay | 5.04 | 3 |
| accent fill on band | 8.87 | 3 |
| accent fill on surface | 6.82 | 3 |
| textOnPrimary mark on accent | 8.87 | 3 |

On these numbers every pair clears 3:1. Pass or fail is a11y-audit's call on rendered pixels.
Hover and press lift the border and the fill through `Style.tone` (0.4 and 0.8 steps). Disabled
blends each role toward band through `Style.disabled`, never opacity.

### Motion and reduced motion

- Fill colour: `Behavior on color`, Motion.micro (130 ms, 60 reduced), Checkbox.qml:104-106.
- Growth on hover and the press response: `StateLayer` response, Motion.micro and Motion.press
  (80 ms, 40 reduced), StateLayer.qml.
- Not animated: the check and the dash appear at once (`visible`, Checkbox.qml:114 and :126); the
  border colour changes without a `Behavior` (Checkbox.qml:102).
- Reduced motion: only the durations shorten (Motion.qml:26); the component has no branch of its own.
- Verdict on how this feels: review-animations, see Hypotheses.

### Pointer geometry

Model: nominal width, the input's side along the approach axis. This is not effective width, and no
trajectories were recorded, so no human average is claimed. ID = log2(1 + D / W). D = 40 px
centre-to-centre is an assumed value chosen to make the arithmetic readable; it is not a measured
layout. Origins: the pointer approaches from a neighbouring row (assumed). Label clicks are assumed
to count as target because the row is the click area; no weight is given to the label or the box.
Trigger-to-panel corridor: not applicable.

| size | painted box | bare input (w x h) | W, height | landing (plus or minus W/2) | ID at D = 40 | ID if height were 24 |
| --- | --- | --- | --- | --- | --- | --- |
| sm | 12 | 20 x 12 | 12 | 6 | 2.12 | 1.42 |
| md | 16 | 24 x 16 | 16 | 8 | 1.81 | 1.42 |
| lg | 24 | 36 x 24 | 24 | 12 | 1.42 | 1.42 |

Labelled rows: the height is max(box, label line). With an assumed 14 px label line, sm gives
ID 1.95 and md stays at 16 px, which is below the 24 px floor used by ux-audit check 3. The 2.5.8
verdict is a11y-audit's. The focus ring is not a hit area; the 8 px gap to the right of the box is
part of the row, so a click there toggles.

### Findings: source-backed defects

Each one is source-reviewed only. Runtime was not exercised.

1. Hover growth is a literal, not a token (Checkbox.qml:159 `hoverScale: 1.15`): the library's
   default target growth is `Motion.hoverScale` = 1.08 (Motion.qml:46, Tokens.qml:61). A person sees
   the box grow 15 percent (16 to 18.4 px) where other targets grow 8 percent. Fix: use
   Motion.hoverScale, or add a named growth token (touches tokens, hence shared).
2. The indeterminate dash is heavier than the check (Checkbox.qml:127-128): the dash is one `Style.indicatorWidth`
   stroke (3 device rows at 1.25) at every size. The check is `check.svg` (stroke-width 2 on a 24 grid), so its stroke is glyph x 2 / 24:
   md 1.0 px, lg 1.5 px, sm 0.75 px. The dash is 2x the md check stroke and 2.7x the sm one. A person
   sees "some" read heavier than "on". The rendered weight is unmeasured: SvgIcon does not rasterise
   offscreen. Fix: derive the dash thickness from the same 2/24 ratio, or the owner accepts the
   heavier dash.

### Redesign proposals (taste, not defects)

- Hover growth: 1.15 or the library's 1.08 (see defect 1). Owner's choice.
- Ring and growth: the box grows by `StateLayer.growth`, the ring keeps its size. With focus and hover together at md,
  the 2 px ring clearance falls to 0.8 px (1.2 px growth per side). Consider growing the ring with the
  box, or keeping the ring outside the growth.
- Mark size: a sm check is 9 px, which is off the icon scale (12, 16, 20, 24). See the source conflict
  below.
- Disabled dimming: the host dims the label (unit: `Style.disabled(Style.text)`); the component dims
  its own roles. Keep as it is; the split is the component's rule.

### Source conflicts

- Checkbox.md:4 says "press(box shrinks 0.88)". Checkbox.qml does not shrink on press (`pressScale`
  stays 1 by default in StateLayer.qml), and AGENTS.md says "A press changes colour only on a body".
  Code and law agree; the record is stale. Owner confirms, then the line is corrected.
- AGENTS.md says "glyphs through Style.iconNear". Checkbox.qml:108-111 says the mark is not snapped
  because iconNear(9) is 12, which would overflow the sm box. The comment gives a reason; the owner
  decides which rule wins.

### Hypotheses (not measured)

- Keypad Enter (Qt.Key_Enter) does nothing, because Checkbox.qml:77 handles Return only. A keyboard
  verdict is a11y-audit's.
- The toggle reads as a snap: the mark and the dash appear at once, while the fill fades over 130 ms
  and the border colour does not fade (Checkbox.qml:102, 104, 114, 126). Whether this feels wrong is
  review-animations'.
- Label line height at sm, which decides the labelled hit height and the sm ID values, is unmeasured.
- Consumer density: unknown.

### Not examined

- Runtime of every state: no Workbench, capture, pixel sample, accessibility tree or trace.
- Light theme and any host backend (`Style.backend`); only `deep-night` tokens are present.
- Reduced motion, measured on a running surface.
- Keyboard, focus, names and the screen reader (a11y-audit).
- Comparison with a sibling: caelestia's controls directory has no checkbox (its `StyledRadioButton`
  is not the same type), so no sibling comparison was possible.
