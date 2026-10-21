# StatRing

A passive output: one fraction bent into a circle, with its reading held in the middle. A bar compares against other bars; a ring reads as one quantity at a glance.
states: none interactive. Rest is the only state; there is no hover, press, focus, selected or disabled. Value clamps to 0..1 and a fraction at or below 0.005 paints no fill arc, so zero reads as none rather than a round-capped dot.
pointer: claims nothing. No MouseArea, HoverHandler, WheelHandler, Keys handler or focus policy; wheel and keyboard pass through to whatever lies beneath.
screen reader: Accessible.StaticText names "label, reading" as one readout (whichever half is set when only one is).
size: natural size is the diameter square; diameter defaults to Style.ringDiameter, stroke to `Style.stroke(box * Style.ringStrokeRatio)` in whole device pixels, the reading is Style.textXl scaled by the live box over Style.ringDiameter and snapped with Style.textNear. A caller that needs another size states diameter and readingSize; the icon is Style.iconNear of the reading size.
content: icon, reading and label stack centred in a column as wide as the square inscribed in the ring's hole; long reading/label text elides on one line and never enlarges the component. The icon is dropped when it would push the stack taller than that square. Formatting is the caller's: "72%" and "3.4 GB" are the same ring.
shape: startAngle/sweepAngle make the form. Open (-225/270, gap at the bottom) holds its label inside the circle; closed (-90/360) is the full ring Avatar draws its progress on.
tokens: accent fill, overlay track, text icon, Prose reading/metadata roles; no local colors or measurements.
motion: none. Data, color, angle and geometry changes repaint the Canvas in the same frame; a one-shot position animation would move a number away from where it was put.
not designed: thresholds (Meter owns them), indeterminate progress (ProgressBar), interaction, dismissal or selection; the host owns the value and never the ring.

## UIX audit

Evidence: source-reviewed. No capture, no runtime, no accessibility tree was read. Numbers are arithmetic from `StatRing.qml`, the token values in `tokens/deep-night.json` (the only theme file) and the stated width model. Owner acceptance: none. Design source: `AGENTS.md` and `tokens/deep-night.json`; there is no `design/` folder.

### Purpose and consequence

The task is a glanceable reading of one fraction: the arc's length and the number in its middle, for a performance card or a resource card. The arc colour only tints a reading that is already there.

### Controls, valid states, implementation

| Control | Values | Implemented |
| --- | --- | --- |
| form | open `-225/270`, closed `-90/360` | yes, `startAngle` and `sweepAngle` (`StatRing.qml:38-39`) |
| value | 0..1, clamped | yes (`StatRing.qml:83`); `value < 0` is not a state (see SR-2) |
| diameter | any number | yes, default `Style.ringDiameter`; no `size` preset (see SR-1) |
| stroke and reading size | any number | yes; the stroke defaults to a proportion of the box (`Style.ringStrokeRatio`) and the reading to `Style.textXl` scaled by the box (see SR-1) |
| content | icon, reading, label | yes, as strings; the label is always the metadata role |
| interaction states | rest only | by design (`StatRing.md` line 4); no hover, press, focus, selected or disabled |

The catalog holds one key, `stat-ring` (variant `open`, `workbench/stories.json:894`). The closed form is reachable only through the unit's form control.

### Pointer, keyboard, wheel, focus, accessibility routes

- Pointer: none. `StatRing.qml` has no `MouseArea`, `HoverHandler` or `TapHandler`, so presses, hovers and wheel events pass to whatever lies beneath.
- Keyboard: none. No `activeFocusOnTab`, no `Keys`. The ring is never a focus stop.
- Accessibility: `Accessible.StaticText` named `label, reading` (`StatRing.qml:49-52`). The component is not interactive, so the a11y-audit method was not run here. Criteria and tree reads are a11y-audit's; the name is source-reviewed only.

### Sizes, empty and long content, failure, cancellation

- Natural size: a constant `D x D` square (`StatRing.qml:45-46`). At defaults `D` = 150, stroke 8, reading 22 px.
- Empty: with no label and no reading, the content column is empty and `Accessible.name` is `""` (see H3).
- Long: the reading and the label are `Prose` roles that do not wrap and elide on the right (`Prose.qml`, `elide: Text.ElideRight` for every role but `body`). The column is `min(D, D) - 2 x stroke - Style.space2` wide: 126 px at defaults, which holds about nine 22 px monospace glyphs (assumed advance 0.6 em).
- Failure: `NaN` draws no arc, since `NaN > 0.005` is false. A negative value clamps to zero, and both hosts substitute zero before the ring sees it (see SR-2).
- Cancellation: none; there is no action to cancel.
- Small diameter: reading and icon scale with the live box and snap to the type and icon scales; the column is the inscribed square of the hole, `sqrt(2) x (box/2 - 1.25 x stroke)`, and the icon is dropped when it would not fit.

### Visual roles and palette pairs

Contrast is computed from the token hex values, not sampled from pixels. The reading is 22 px bold, which qualifies as large text (WCAG 1.4.3), so 3 is its requirement.

| Element | Role | On | Ratio | Requirement | Result |
| --- | --- | --- | --- | --- | --- |
| reading | `Style.text` `#f0ecf5` | band `#271e30` | 13.71 | 3 (large) | pass |
| reading | `Style.text` | surface `#3b3145` | 10.53 | 3 (large) | pass |
| label | `textMuted` `#c5bad1` (10 px) | band | 8.61 | 4.5 | pass |
| label | `textMuted` | surface | 6.61 | 4.5 | pass |
| arc fill | `accent` `#d9b4ea` | overlay track `#4c4357` | 5.19 | 3 (1.4.11) | pass |
| status fills | warning 5.34, danger 5.17, success 5.51 | overlay track | | 3 | pass |
| track | `overlay` `#4c4357` | band | 1.71 | 3 if the track is data | see S2 |
| track | `overlay` | surface | 1.31 | 3 if the track is data | see S2 |

### Motion and its reduced-motion form

None. No `Behavior`, no `Animation` (grep of `StatRing.qml`). The arc redraws on each value change (`StatRing.qml:95`), so it snaps. The reduced-motion form is therefore trivially met. review-animations was not run because nothing animates. See P2.

### Pointer geometry

- Input shape: none. No handler accepts a press, a hover or a wheel, so the `D x D` box is not in any hit path.
- Painted size: the stroke's outer edge sits at radius `D/2 - stroke/4`. The painted disc is `D - stroke/2`: 146 px at defaults, 48 px at `D` 52, 61 px at the dashboard's 64 with stroke 6, 376 px at 380.
- Target arithmetic: not a target. If a host made the whole ring a target, the width model is the painted disc (`W` = 146 px at defaults) and `ID = log2(1 + D/W)`. With an assumed `D` of 300 px: `ID` = 1.61 bits at defaults, 2.86 bits at `D` 52. These are assumptions, not measurements, and no finding rests on them.
- Label origin (assumed): the label is the last child of a centred column, so its origin depends on the stack height: icon 22, spacing 2, reading line, spacing 2, label line. The label sits in the open form's gap, the 90 degrees from 45 to 135 degrees (canvas angles, y down, so the bottom). Weight: regular, from the metadata role. Size: 10 px. Colour: `textMuted`.
- Corridor and timing: not applicable; no popup.

### Findings

Defects are source-backed and each cites the file and line. Proposals are redesign or taste and carry no defect weight.

**SR-1 (major, shared=true): no size preset, so the `lg` ring is hollow with tiny text.**
- Evidence: `StatRing.qml` takes the diameter from `Style.ringDiameter`, derives the stroke from the box (`Style.ringStrokeRatio`) and scales the reading with it, but `tokens/deep-night.json` has no `sizes.StatRing` and `AGENTS.md` requires every sized type to resolve a preset through `Style.size`. `workbench/units/StatRing.qml` takes `lg` to 380 by stating the diameter.
- Expected: one scale per instance, with a `size` preset and a stroke and reading that scale with it.
- Actual: a host states `diameter` by hand; there is no preset name.
- Fix: add `sizes.StatRing` to `tokens/deep-night.json`, add a `size` property resolved by `Style.size("StatRing", size)`, and keep `diameter` as the escape hatch. Reaching 380 needs the display and hero steps, because `Style.textNear` stops at `textXl`, so a `Style` change is needed too.

**SR-2 (minor, shared=false): an unknown reading is painted as zero.**
- Status: open: the no-data look is the owner's ruling (P1); the host change stays outside qsm-shell.
- Evidence: `StatRing.qml:83` clamps the value to 0..1, so a host that passes `Math.max(0, usage)` before the first reading shows an empty ring with "—" as the reading.
- Expected: unmeasured is distinct from zero.
- Actual: the arc is an empty track, the same drawing a measured 0 produces. Only the dash tells them apart.
- Fix: the library gets an explicit no-data form (P1). The host passes `-1` unclamped. The host change is outside qsm-shell.

### Proposals

- P1: a no-data form for SR-2, for example a muted or dashed track. The look is the owner's ruling.
- P2: motion. The arc snaps on every sample, while `Meter.qml` eases its fill (`Behavior on width`, `Motion.fast`). Decide whether readings ease. If they do, the reduced-motion form shortens the duration, because a one-shot calms by getting shorter. Today the ring has no reduced-motion form.
- P3: the comment at `StatRing.qml:54-58` says the column gives back "one rhythm step", but `:59` subtracts `Style.space2` (8 px), which is the second step (`space1` is 4). Decide the number, then the comment.
- P4: the proof for the `0.75` inset (`:72`) and the `0.005` threshold (`:86`). `AGENTS.md` asks for the derivation in the comment. The inset puts the painted edge `stroke/4` inside the box, which is 2 px at defaults.
- P5: `caelestia` (`components/controls/CircularProgress.qml`) draws the remainder with a gap sized from stroke and spacing, and an optional end dot. StatRing draws the track under the fill. The zero threshold stays: caelestia clamps to `1/360` and paints a dot at zero, which the comment at `StatRing.qml:83-86` rejects. Whether to add an end dot is taste.
- P6: the label's role is fixed at metadata (10 px). A consumer cannot raise the label with the reading. Consider a role property or a slot.
- P7: the unit's `sm` option is a 48 px diameter (Control `lg`). Rename it when SR-1 adds the presets.

### Source conflicts

- S1: `StatRing.qml:13-16` says a closed ring "pushes its label outside the circle". A host keeps the label inside a closed 64 px ring (default `-90/360`). The owner decides which holds.
- S2: `AGENTS.md`, surface ladder, says an inactive track is `overlay`, which is 1.71:1 on band and 1.31:1 on surface. `ui-audit` pass 4 says data marks need 3:1 against what they sit on (WCAG 1.4.11). The owner decides whether the track is a data mark, that is, whether a reader must see the full extent to read the arc.

### Hypotheses

- H1: at the dashboard size (`D` 64, stroke 6), the bottom corners of the label "Storage" sit about 0.9 px from the inner stroke edge. Assumed label width 38 px, stack about 28 px, so the corners are at (19, 14) and 23.6 px from the centre against an inner edge at 24.5 px. Unmeasured.
- H2: `Prose` children are `Text` items, which may expose their own text to a screen reader, duplicating the root's "label, reading" name. Needs the accessibility tree.
- H3: `Avatar.qml`'s ring passes no reading and no label, so its accessible name is empty and its progress is in no name. Whether it matters is a11y-audit's call.
- H4: for an odd diameter, `Avatar.qml`'s width is `size` plus an even ring room, so `cx = width / 2` lands on a half pixel. Unmeasured.

### Not examined

- Rendering and pixels: no capture; `SvgIcon` does not rasterise offscreen in any case.
- Accessibility tree and keyboard routes: not read; the component is not interactive.
- Themes and variants: only `deep-night` exists in `tokens/`. No light, high-contrast or scale-factor variant.
- In-situ sizes: the real dashboard and performance values, and the Avatar ring in its own surface.
- caelestia: compared by source only (`CircularProgress.qml`).
