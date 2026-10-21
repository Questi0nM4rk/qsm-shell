# Meter

A passive level readout for a quantity with no end (battery, thermal); a progress bar measures a process toward an end and owns indeterminate, a meter owns thresholds and has none. Not a disabled Slider: a slider is input, a meter is output and never offers the pointer a hand.
states: rest(track overlay, fill primary) breached(low/high crossed, fill warning; the reading is unwelcome, not failed) disabled(track and fill each through Style.disabled, never opacity, layers stay opaque)
actions: none; no pointer, wheel, keyboard, focus or action API; the host owns value and thresholds
geometry: horizontal fills from the start edge, vertical from the bottom; value clamped 0..1; length alone carries the reading, low/high only tint it
tokens: trackThickness overlay primary warning band Style.disabled
motion: fast+moveEasing on the value (the fraction the fill is drawn from, so a host resize never glides), removed under reduced motion; micro+standardEasing on fill colour; a snapping level reads as jitter
size: fill extent is rounded to whole pixels
screen reader: no role of its own; the host names the reading
not designed: labels, policy, indeterminate, interactive states; use ProgressBar for a process, Slider for input

## UIX audit

Evidence: source-reviewed only. No Workbench session, capture, zoom or pixel sample was taken; live geometry was not read. Contrast figures are WCAG ratios computed from the token hex values in `tokens/deep-night.json`, not from rendered pixels. No owner acceptance is claimed.

Read: `qml/QsmShell/Components/Meter.qml`, `workbench/units/Meter.qml`, the one story key `meter` (variant low) in `workbench/stories.json`, `docs/components/Meter.md`. Caelestia has no level sibling in `components/controls/`; its `StyledProgressBar.qml` is a process bar with an indeterminate state, so it is not a comparison for a meter.

### Purpose and consequence

Shows how full or how hot a quantity is (battery, temperature, load), so a person reads it at a glance. A missed reading means a battery goes flat or a CPU overheats unnoticed. Consumers: the battery popout and the performance tab.

### Controls and states

- Properties: `value` (clamped to 0..1, `Meter.qml:39`), `low` and `high` (-1 means no threshold, `Meter.qml:31-32`), `fill`, `trackColor`, `thickness`, `orientation`. All implemented.
- States: rest, breached (`Meter.qml:40, 44`), disabled by colour (`Meter.qml:48-49`). The five interactive states do not apply: there is no interaction.
- Unit controls (`workbench/units/Meter.qml`): value empty, low, high (no full, no middle); threshold none, low, high (no both-sides case); axis; enabled.

### Routes

Pointer: none. Wheel: none. Keyboard: none. Focus: none. Accessibility: the component sets no `Accessible.*` property (grep of `Meter.qml`), so the reading reaches assistive tech only if the host names it. Consumers do not name it in the source read.

### Sizes, empty, long, failure, cancellation

- Horizontal: length from the host; cross size `thickness`, default `Style.stroke(Style.trackThickness, root)` (4, `tokens/deep-night.json`, snapped to whole device pixels). Natural size is 0 by 4, so a host that sets no width sees nothing.
- Vertical: the same, rotated; natural size is `thickness` by 0.
- Empty: value 0 gives a fill width of 0 (`Meter.qml:63`), track only. Full (value 1) is not in the unit.
- Long content: not applicable.
- Failure: `undefined` or NaN value is not guarded (`Meter.qml:39`, hypothesis H3). Out-of-range values clamp.
- Cancellation: not applicable (no action).

### Visual roles and pairs

Token values, WCAG contrast (source-reviewed, not sampled):

| Pair | Ratio | Note |
| --- | --- | --- |
| track `overlay` #4c4357 on `band` #271e30 | 1.71:1 | 1.4.11 asks 3:1 for meaningful parts; ruling is a11y-audit's |
| fill `accent` #d9b4ea on `overlay` | 5.19:1 | passes 3:1 |
| breached fill `warning` #d9c284 on `overlay` | 4.78:1 | passes 3:1 |
| fill `accent` on `band` | 8.87:1 | |
| breached fill `warning` on `band` | 9.13:1 | |
| disabled | not computed | `Style.disabled` blends toward `band` by `opacityDisabled` (`Style.qml:107-113`); that value was not read |

Track is `overlay`, which matches AGENTS. The fill is `primary`, the active part of a track; the owner confirms the role.

### Motion and its reduced-motion form

- Fill extent: `Behavior on width` and `height`, `Motion.fast` (180 ms) with `Motion.moveEasing` (`Easing.InOutCubic`, `Motion.qml:128`), `Meter.qml:70-75`.
- Fill colour: `Behavior on color`, `Motion.micro` (130 ms) with `Motion.standardEasing` (`Easing.OutCubic`, `Motion.qml:120`), `Meter.qml:76-78`.
- Reduced motion: `fast` becomes 80 ms and `micro` 60 ms (`Motion.qml:26, 56`). The value Behavior is disabled under `Style.reducedMotion`; the colour Behavior stays.

### Pointer geometry

Not applicable. The component has no input shape: no `MouseArea`, no handler, nothing to hit. So D, W, ID, landing tolerance, neighbour interference and any popup corridor have no subject. Modelled for reference only, if a host made the track seekable with the painted band as its grab zone: the width model is Shannon, ID = log2(1 + D/W). With W = 4 px (the cross size the unit paints) and D = 100 px (assumed approach, not measured), ID = log2(1 + 100/4) = 4.70 bits. Label origin: none, the host owns any label. Weights: none assumed.

### Proposals (not defects)

- Thresholds are exercised only by the workbench: the breached state, the `warning` token and the threshold unit control have no other use, and a host may avoid `low` because it paints amber where danger is meant. Owner decides: keep, or delete (prime directive).
- A threshold is invisible. A person sees the fill turn amber at 20 percent with no mark where 20 percent is. A short tick at the threshold position would show where the line is (AGENTS allows "a line inside is content, a track, a meter").
- Standard 7 (review-animations): the fill animates `width`/`height`. The cost is one childless Rectangle repaint with no parent layout. A `transform: scale` would squash the rounded cap during the move, so no cheaper property keeps this shape. Kept, with the reason recorded.
- Add a "full" (value 1) option and a both-thresholds option to the unit (`workbench/units/Meter.qml:32-42`), so the edges are seen.
- Natural width 0 (`Meter.qml:51`) is not a constant; AGENTS asks for one. Give the horizontal natural width a `Style` size or document that the host must set the length.
- `Motion.moveEasing` and `Motion.standardEasing` are Qt cubic built-ins (`Motion.qml:120, 128`). The animate skill names the custom curves `0.77, 0, 0.175, 1` (ease-in-out) and `0.23, 1, 0.32, 1` (ease-out), and QML can carry them through `Easing.BezierSpline` (`easing.bezierCurve`). This is a `Motion.qml` change, so it is shared and affects every component.
- The -1 sentinel for "no threshold" is a number inside a component (AGENTS: no numbers in a component). A `NaN` or an explicit boolean would avoid it. Taste, low priority.

### Source conflicts

- Reduced motion: AGENTS "shortens a duration" against AGENTS "a one-shot position animation is REMOVED, not shortened", against `Motion.qml:22-23`, which still says it shortens, against review-animations standard 8. The Meter follows the removal law. Owner ruling needed.

### Hypotheses (not measured)

- H1: the breached state is colour only (`Meter.qml:44`). The threshold is not drawn and the reading does not say "low" in text. Whether this fails 1.4.1 is a11y-audit's ruling.
- H2: no `Accessible` role, name or value on the component. The reading is pixels only unless the host names it. a11y-audit's.
- H3: a NaN or undefined value propagates: `Math.min` and `Math.max` return NaN, which reaches `width`. Battery guards with `?? 0`; the performance tab does not guard `tempC` in the read source. Unverified.
- H4: the doc says "fills from the start edge"; the code anchors `left` (`Meter.qml:59`). Qt does not mirror anchors, so a right-to-left layout would fill from the wrong end. No RTL consumer seen.
- H6: the vertical path (`Meter.qml:59-64` with `width` undefined) has no workbench proof in the unit read; it is source-reviewed only.

### Not examined

Live geometry (channel 2): not read. Captures, zoom, region stats and pixel samples: not taken (no Workbench session, per scope). Light and high-contrast themes: only the deep-night token values were read. Passes 1, 2, 5, 6, 8: no children, text or shadows to measure beyond the fill. Ux-audit routes: none exist on the component. a11y criteria: a11y-audit's, not run here.

### Motion verdict (review-animations, source-reviewed)

Hold: neither Block nor Approve. No Block trigger: no keyboard animation, no scale from zero, no ease-in, durations inside the bounds (180 and 130 ms, under 300), and interruption holds because a `Behavior` retargets from the current value. The feel cannot be judged from code; the check is a frame-by-frame run with the duration raised 2 to 5 times, in a real window, when the owner asks for one.
