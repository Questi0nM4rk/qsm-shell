# SvgIcon

A non-interactive semantic glyph renderer for the shell's icon vocabulary; a parent action or label owns all input and accessible interaction.
states: rest inherits its supplied `color`; disabled, selected, danger and loading colours are decided by the owning component through `Style`, never hidden in the glyph.
actions: none; pointer, keyboard and wheel pass through, and SvgIcon never claims focus.
screen reader: decorative by default when beside an accessible label; a standalone meaningful icon must be named by its owning control, not duplicated as a second target.
size: the caller supplies one `size` from the icon scale; the painted glyph is square and remains bounded by that size regardless of its source SVG viewbox.
tokens: caller-selected icon scale and semantic foreground role; no local colour, padding or hit target.
motion: no local motion; state changes belong to the owner.
not designed: clickable icons, badges, image thumbnails or arbitrary SVG documents; use IconButton, Badge, Image or a specialized component.

## UIX audit

Evidence: source-reviewed only. Runtime-exercised: none. Owner-accepted: none. No window, capture or tree dump was used. Colour ratios are computed from the hex values in `tokens/deep-night.json`; glyph geometry is arithmetic on the shipped SVG viewBox. Rendered pixels were not sampled.

### Purpose and consequence

The component finishes one task: a small glyph beside text names the kind of a row, button or readout, or its state. When it fails, the reader loses a cue the label does not carry, or sees an empty slot where the cue should be.

### Controls and states

- `name` (string; `""` draws nothing): implemented. `SvgIcon.qml:20`, bound at `:32-34`. An empty name is a legitimate state, documented at `:16-19`.
- `size` (int, default `Style.iconMd`): implemented. `SvgIcon.qml:21`, footprint `:24-27`, raster `:35`. Any integer is accepted. The icon scale is `Tokens.qml:42-45` (12, 16, 20, 24). "One size from the icon scale" is a convention, not a check (conflict C1).
- `color` (colour, default `Style.text`): implemented as MultiEffect colorisation, `SvgIcon.qml:40-45`.
- Valid states: rest uses the supplied colour. Selected, danger and disabled are owner colours, shown only in the unit (`workbench/units/SvgIcon.qml`, `foreground` control). Loading has no colour in the unit, which matches the doc's "owner decides" rule.
- Not expected and not present: actions, focus, hover, press.

### Routes

- Pointer: passes through. The file has no MouseArea, HoverHandler, TapHandler or Accessible attribute, so the glyph takes no input.
- Keyboard and wheel: pass through. No Keys handler, no `activeFocusOnTab`.
- Focus: never claimed. The focus ring belongs to the parent.
- Accessibility: no role or name is set in the file. The doc's "decorative by default" is not enforced in source. Whether Qt's Image is exposed to the platform tree is unverified (hypothesis H4). Criteria and tree reading belong to a11y-audit.

### Sizes, empty, long, failure, cancellation

- Sizes: the footprint is `size` by `size`, fixed at `SvgIcon.qml:24-27`. The stroke is `size / 12` px at scale 1 (viewBox 24, stroke-width 2): xs 1.00, sm 1.33, md 1.67, lg 2.00 px.
- Empty: an empty name sets the Image source to `""` and paints nothing. The box still reserves `size` by `size`, so an empty name reads as a gap, which is the intended slot behaviour.
- Long content: not applicable; the glyph has no text.
- Failure: an unresolved name paints nothing and emits no signal (`SvgIcon.qml:32-34`, the Image `status` is never read). Finding D1.
- Cancellation: none. Assets load asynchronously (`:36`); no cancel path exists.

### Consumers

About 25 call sites in the library's own components use the component. Names that arrive as bindings (for example `root.icon`, `root.badgeIcon`, `root.thumbIcon`, `root.iconName`) were not checked.

### Visual roles and palette pairs

All 94 shipped assets draw strokes in `#ffffff` (92 stroke attributes, 4 white fills, two files without a stroke attribute). Colorisation by luminance therefore tints each glyph exactly to `color`. WCAG 2.2 relative-luminance contrast from the token values:

| pair | ratio | source |
| --- | --- | --- |
| `text` on `band` | 13.71 | `deep-night.json` colour |
| `textMuted` on `band` | 8.61 | same |
| `accent` on `band` | 8.87 | same |
| `accent` on selected layer (`accent` at 0.12 over `band`) | 6.84 | `opacity.selected` 0.12 |
| `danger` on `band` | 8.84 | same |
| `text` on `surface` | 10.53 | same |
| `accent` on `surface` | 6.82 | same |
| disabled `text` on `band` (`Style.disabled`, k 0.35) | 2.90 | `opacity.disabled` 0.35 |

The disabled pair is an inactive control, which WCAG 1.4.3 exempts from the text threshold. Whether a disabled glyph still needs 1.4.11's 3:1 is a11y-audit's call, not this record's.

### Motion and reduced motion

None in the file. The asynchronous load is not animated, so reduced motion has no form to define here. The review-animations skill has no surface to judge.

### Pointer geometry

- Input shape: none. The glyph has no handler, so its hit area is 0 px and the pointer reaches the parent.
- Painted box: `size` by `size` (xs 12, sm 16, md 20, lg 24 px).
- Ink inside the box (assumption, not measured): the shipped assets are lucide glyphs (the header of `activity.svg` names lucide-static, ISC; other files were not opened) on a 24-unit grid with a 2-unit stroke. If the keyline padding is 2 units, the ink sits about 1 unit (4.2 % of the box) inside each edge.
- D, W, ID: not applicable to the glyph, because no pointer task targets it. The reference case, if the glyph alone were a target at distance D = 100 px (illustrative assumption): width model W = box edge, ID = log2(1 + D / W). At xs, W = 12, ID = 3.22 bits, landing tolerance ±6 px (half-width, effective-width assumption). At lg, W = 24, ID = 2.37 bits, tolerance ±12 px.
- Target floor: a glyph alone is below the 24 × 24 px pointer floor at xs, sm and md. AGENTS.md gives the owning control the minimum: its state layer is at least `Style.iconLg` each way, centred. The parent must provide that floor.
- Label origins and weights: not applicable; the component has no label.

### Findings

**Source-backed defects**

- D1 (minor): an unresolved name renders nothing and gives no signal. The Image `status` is never read (`SvgIcon.qml:32-37`). Caelestia's `components/MaterialIcon.qml` is a text icon font, so an unknown name prints as text and is seen; this component's failure is invisible. Fix in the file: read `base.status` and `console.warn` with the name when it becomes `Image.Error`. Not shared.
- D2 (low): `workbench/units/SvgIcon.qml:10` fixes `name` to `battery-full`, and the unit's `controls` declare only `variant` and `size`. The owner never sees the empty-name slot that `SvgIcon.qml:16-19` documents as legitimate. Fix in the unit: add a `name` control with two real names and `""`. Not shared. Status: fixed (source-reviewed, load-checked); the unit now declares a `name` control with `battery-full`, `wifi` and the empty name. Not owner-accepted.

**Redesign proposals (taste, owner decides)**

- P1: the raster factor `root.size * 2` (`SvgIcon.qml:35`) is a literal. AGENTS.md's "No numbers in a component" applies. Derive the factor from the output's device pixel ratio or name it.
- P2: `size` is `property int` (`SvgIcon.qml:21`). `Checkbox.qml:116` passes `_box * _markRatio`, a fraction, which the int property converts silently. The 3:4 ratio in `Checkbox.qml:108-110` is therefore approximate.
- P3: the stroke grows with size (size / 12 px). Two of the four steps (sm, md) are non-integer at scale 1, which is the stroke-smear case in ui-audit pass 3. Measure at zoom before any change (H1).
- P4: stroke weight has no token. A fixed weight per scale is a design choice, not a fix.
- P5: each glyph adds one MultiEffect node. Long lists of rows multiply it per row. Cost is unmeasured.

**Source conflicts (owner ruling)**

- C1: `docs/components/SvgIcon.md:7` ("one size from the icon scale"), AGENTS.md ("glyphs through `Style.iconNear`") and `Tokens.qml:42-45` on one side; `Checkbox.qml:108-116` on the other, which deliberately keeps a proportional mark size and cites M3. The owner decides whether `size` snaps to the scale or stays settable.

**Hypotheses (observed in source, not measured)**

- H1: the sm and md strokes (1.33 and 1.67 px at scale 1) soften on the pixel grid.
- H2: a name change, or the first asynchronous load, may leave a blank frame. Judge in a live window.
- H3: at an output scale above 2, the 2x raster is softer than the device. Output scale is not known from source.
- H4: Qt's Image may expose a graphic node to the accessibility tree, which would contradict "decorative by default". Route to a11y-audit.

**Not examined**

- Rendered pixels, zoom crops, the platform tree, and any live window.
- Light or other themes: `tokens/` holds only `deep-night.json`.
- Output scales above 2x, and the cost of MultiEffect in long lists.
- The meaning each consumer gives its glyph, and whether colour alone carries that meaning (a11y-audit's 1.4.1 check).
- Motion: none to judge.
