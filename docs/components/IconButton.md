# IconButton

A compact, named action for dense shell controls; the caller supplies the glyph and owns the effect.
states: rest, hover, press, focus and disabled; hover and press use the shared StateLayer response, focus rings the complete hit target, disabled blends every painted role through Style.disabled.
actions: pointer click, Space, Enter and the `actions` entry all call `activate()` and emit clicked; callers never synthesize pointer events.
pointer: the whole padded body is the target and reports a pointing cursor; wheel does nothing and propagates.
keyboard: T.Control tab focus and activation; focus remains visible until it leaves.
screen reader: Accessible.Button with accessibleName (defaults to icon for a usable fallback; callers provide a human name where the glyph alone is ambiguous).
size: icon and insets stay caller-settable; the natural target is icon plus the control's paddings and never grows with content.
tokens: iconMd, space3, text, disabled, accent, Motion and StateLayer; no local measurements or colors.
motion: StateLayer's fast press acknowledgement and restrained hover response, removed or reduced by Style.reducedMotion.
not designed: label-bearing primary buttons, loading, toggled state and menus; Capsule, Segmented or a surface-owned row express those concepts.

## UIX audit

Evidence: source-reviewed only. No Workbench session, preview, capture, key test or tree dump was run.
Owner acceptance: none. Numbers are computed from `tokens/deep-night.json` through the `Style` formulas.

### Purpose and consequence

One glyph that starts one named action inside a dense control (transport buttons, a row's action,
a calendar step, a copy button). Activation emits `clicked`; the caller owns the effect.

### Controls, states, implemented

- Public controls: `icon`, `size`, `color`, `padding`, `accessibleName`, `enabled`, `activate()`,
  `clicked`, `opticalOffset`.
- Rest, hover (disc lift and glyph growth), press (disc lift and glyph push), keyboard focus ring,
  disabled (colour blend): all five implemented through `StateLayer` (IconButton.qml:55-66,
  StateLayer.qml:115-183).
- Not designed: loading, menu, label-bearing, toggled. NotificationCenter.qml:295-296 patches a
  toggle by hand with `Accessible.checkable` and `Accessible.checked`.
- Unit controls: one group, `state` enabled and disabled (workbench/units/IconButton.qml:22-27).
  No size, padding, colour or compact case. BACKLOG R2/R3 confirmed (IB-09).

### Routes (source only)

- Pointer: TapHandler in StateLayer fires on release inside the bounds; a drag past the threshold
  cancels (StateLayer.qml:52, 170-175). A click focuses the control without a ring
  (IconButton.qml:63, StateLayer.qml:175-181). Hand cursor when enabled (StateLayer.qml:164-168).
- Keyboard: `focusPolicy` StrongFocus (IconButton.qml:22). Return, Enter and Space call `activate()`
  on key press (IconButton.qml:68-70). Escape has no route.
- Wheel: no handler in IconButton or StateLayer; the wheel propagates.
- `actions` entry: text is `accessibleName`, runs `activate()` (IconButton.qml:36-38).
- Focus ring: keyboard only, from the control's `visualFocus` (StateLayer.qml:72, 147-162).
- Accessibility: role Button, name `accessibleName` (IconButton.qml:28-29). Verdicts are a11y-audit's.

### Sizes, empty, long, failure, cancellation

- Size: raw pixel int, default `Style.iconMd` = 20 (IconButton.qml:10). No preset name. Padding is
  fixed at `Style.space3` = 12 (IconButton.qml:26). Natural target = size + 2 x padding (IconButton.qml:24-25).
- Empty: an empty `icon` string draws nothing and gives an empty name (IconButton.qml:9, 12).
- Long content: not applicable, one glyph.
- Failure: an unknown icon name draws nothing. SvgIcon.qml:29-38 sets `Image.source` from the name
  with no status check (IB-06).
- Cancellation: drag past the threshold (StateLayer.qml:52). Disabled: `activate()` returns without
  emitting (IconButton.qml:31-34).

### Visual roles and palette pairs

WCAG relative luminance, as `Style._luminance` defines it (Style.qml:185-188).

| Role | Fill | Pair | Ratio |
| --- | --- | --- | --- |
| rest glyph | `text` #f0ecf5 on `band` #271e30 | glyph on band | 13.71:1 |
| rest glyph (desktop) | `textMuted` #c5bad1 on `band` | glyph on band | 8.61:1 |
| hover disc | `lift(surface, 0.4)` #51495b | `text` on disc | 7.36:1 |
| hover disc | same | `textMuted` on disc | 4.63:1 |
| press disc | `lift(surface, 0.8)` #5d5567 | `text` on disc | 6.06:1 |
| focus ring | `accent` #d9b4ea | ring on `band` (assumed neighbour) | 8.87:1 |
| disabled glyph | `Style.disabled(text)` | on band | 2.90:1, inactive, exempt from 1.4.3 |

Source conflict SC-1 concerns the rest surface, not this table.

### Motion and reduced motion

- Press acknowledgement: `Motion.press` 80 ms, reduced 40 ms (Motion.qml:24).
- Hover response: `Motion.micro` 130 ms, reduced 60 ms (Motion.qml:26), `Motion.standardEasing` OutCubic (Motion.qml:120).
- Glyph scale: `hoverScale` 1.08, `pressScale` 0.94 (Motion.qml:46-47; tokens `motion.hoverScale`, `motion.pressScale`).
- Interruption: the `response` Behavior retargets from the current value (StateLayer.qml:126-131).
- Reduced motion: durations shorten; the scale does not (IB-03). Judgement is review-animations'.

### Pointer geometry

- Input shape: a square of side D, the control's bounds, because the handlers sit on StateLayer with
  `anchors.fill` (StateLayer.qml:115-117, 164-183).
- Painted shape: a circle of diameter D (hover disc at `focusRadius` = height / 2,
  IconButton.qml:61, StateLayer.qml:115-124). The focus ring is a concentric circle of diameter D + 8
  (StateLayer.qml:147-157).
- Default: D = 20 + 2 x 12 = 44. The painted glyph box is 20 px; the visible play triangle is 11.7 px wide.
- Corner excess: 1 - pi/4 = 21.5 % of the input square lies outside the disc. A corner is 0.207 D
  from the disc edge: 9.1 px at D = 44, 4.1 px at D = 20, 5.0 px at D = 24 (IB-05).
- Instances: D = 24 (PopoutRow.qml:74-75, iconSm 16 + space1 4), D = 20 (ColorPickContent.qml:201-202,
  iconXs 12 + space1 4), D = 32 (MonthCalendar.qml:35, 37, iconSm 16 + space2 8), D = 40
  (NotificationCenter.qml:294, 303, (controlHeight 40 - iconMd 20) / 2 per side).
- Width model: W = D along the motion axis. Distance D_m = W + S, S the gap to the neighbour.
  S = 8 is an assumption (`Style.space2`); the desktop row's real gap is not read.
- Fitts index ID = log2(1 + D_m / W), model values:
  - W 44, S 8: D_m 52, ID 1.13 bits (default).
  - W 24, S 8: D_m 32, ID 1.22 bits (compact, PopoutRow).
  - W 20, S 8: D_m 28, ID 1.26 bits (compact, ColorPickContent).
  The distance is centre to neighbour centre. Trajectories from far away are not modelled.
- Label: none. Origin: target centre (assumption). Weights: none, uniform (assumption).
- Landing tolerance: the effective width is not measured. No human average is claimed.
- Neighbour interference: input squares do not overlap at S of 0 or more. The focus ring sits 4 px
  outside the disc and takes no hits.
- Popup corridor: not applicable.

### Findings

Defects are source-backed. Shared means the fix touches a file other than IconButton.qml or this record.

- IB-01 (medium, shared). The default name is the glyph key. IconButton.qml:12 sets
  `accessibleName: icon`, used at lines 29 and 37. A screen reader announces "skip-back", "shuffle"
  or "repeat-1" at MediaTab.qml:203, 211, 226, 233 (no `Accessible.name`). ColorPickContent.qml:194-203
  changes the name from "copy" to "check" on copy. MonthCalendar.qml:35, 37 announce "chevron-left"
  and "chevron-right". Fix: make `accessibleName` required with no default and pass human names at call sites.
- IB-02 (low, shared). Two names for one control. Consumers set `Accessible.name` (DashboardTab.qml:299,
  307, 316; MediaTab.qml:222), which replaces the binding at IconButton.qml:29, while the action text
  still reads `accessibleName` (IconButton.qml:37). Fix: one source, and consumers stop overriding it.
- IB-03 (medium, shared). Reduced motion keeps movement. The glyph scales by 1.08 and 0.94
  (StateLayer.qml:134-139, Motion.qml:46-47), and nothing gates the scale under `Style.reducedMotion`.
  Only durations shorten (Motion.qml:24, 26). This record's motion line says "removed or reduced",
  which holds for durations only. Verdict is review-animations' (standard 8). Fix: scale 1 under
  reduced motion, in Motion.qml or in StateLayer's Binding.
- IB-04 (medium, shared). A compact copy target is 20 px. ColorPickContent.qml:201-202 gives
  12 + 2 x 4. The 24 px floor is ux-audit's desktop-pointer value; the WCAG 2.5.8 verdict and the
  spacing exception are a11y-audit's and were not checked. Fix: the consumer passes a padding that
  reaches 24, or the size table gives IconButton a minimum natural size (see IB-08).
- IB-05 (low, shared). A hover with no disc at the corners. The input is the square
  (StateLayer.qml:164-183); the disc is a circle (StateLayer.qml:115-124, IconButton.qml:61). At
  D = 44 the corner is 9.1 px outside the disc. The pointer shows the hand cursor and the glyph grows
  with nothing painted behind it. Fix: circular input (containmentMask on StateLayer) or a disc
  matching the input (see proposal P7).
- IB-06 (medium, shared). Silent failure. IconButton.qml:9 accepts "" and any unknown name. SvgIcon.qml:29-38
  has no error path, so the control draws an empty disc and still accepts clicks. Fix: SvgIcon fails
  loud, naming the icon, per the project's fail-loud rule.
- IB-07 (low, fixed: source-reviewed, load-checked, not owner-accepted). The play offset rests on a wrong premise. IconButton.qml:13-18 assumes the glyph is
  half the box and centred. The asset (qml/QsmShell/assets/icons/play.svg, polygon 6,3 20,12 6,21 on a
  24 box) has its bounding box centre at 0.542 of the box and its centroid at 0.444, so the centroid
  sits size/18 left of centre. The code applies +size/12 (IconButton.qml:18). The centroid lands
  size/36 right of centre: at size 20, the needed shift is 1.11 px and 1.67 px is applied, leaving the
  centroid 0.56 px right. At sizes 16 and 34 the shift is fractional (1.33 px, 2.83 px), against the
  integer-geometry rule (IconButton.qml:47). Fix: derive the shift from the asset and round to whole pixels.
  Now `Math.round(size / 18)`, an int.
- IB-08 (low, shared). Padding does not scale with size. IconButton.qml:26 fixes `padding` at
  `Style.space3`, while the size is free. Consumers compute padding by hand (NotificationCenter.qml:294,
  303). Disc to glyph ratio is 3.0 at size 12 and 2.0 at size 24 with the default padding. The
  project law says insets scale through `Style.rhythm`. Fix: a `sizes.IconButton` table in the tokens, with
  padding derived from the preset.
- IB-09 (low, fixed: source-reviewed, load-checked, not owner-accepted). Known issue confirmed. workbench/units/IconButton.qml:22-27 has only the enabled and
  disabled options, and stories.json:545-560 holds one key, `icon-button`. docs/BACKLOG.md:48 (R2/R3).
  Fix: add `size` options (iconXs, iconSm, iconMd) and a padding option to the unit's `controls`.
  The unit now has `size` (iconXs, iconSm, iconMd) and `padding` (default space3, compact space1) groups.

Source conflicts (owner ruling needed):

- SC-1. AGENTS.md says the surface ladder is 1.30:1 on band. The deep-night colours, #42394c on #271e30,
  compute to 1.46:1 with `Style._luminance` (Style.qml:185-188). One of the two is stale.
- SC-2. The icon scale differs between library and desktop. Library: 12, 16, 20, 24 (tokens `icon`;
  Style.qml:219-222). Desktop: `Theme.iconXl` = 34 (qsm-desktop shell/theme/Theme.qml:248), used for the
  play button at MediaTab.qml:218-222.

Proposals (taste, not defects):

- P1. Glyph-only controls get a human name at the call site, and a missing one fails at load (IB-01).
- P2. Put compact sizes in the size table so the 24 px floor is not hand-computed (IB-04, IB-08).
- P3. A `checked` state for toggled glyphs, or a written rule that toggles are caller-patched
  (NotificationCenter.qml:295-296).
- P4. Keys activate on press (IconButton.qml:68-70) while the pointer activates on release
  (StateLayer.qml:174). Native buttons activate Space on release. Consider moving keys to release.
- P5. A bare glyph has no visible label. A tooltip reading `accessibleName`, under ui-design's one-delay rule.
- P6. The focus ring is 2 px, 2 px outside a 44 px disc (StateLayer.qml:147-157). a11y-audit checks
  2.4.11 and 2.4.13 against it.
- P7. Choose one shape for the hover (IB-05): a rounded-square disc matching the input, or a circular input.

Hypotheses (unmeasured):

- H1. Holding Return or Space may repeat `activate()`. IconButton.qml:68-70 does not test
  `event.isAutoRepeat`. Trial: hold Enter for one second on a focused control with a counter in the unit;
  pass means one `clicked` per press.
- H2. The wheel propagates. Source says no handler exists; a runtime check needs a scrollable parent.
- H3. PopoutRow.qml:81 dims the whole control by `opacity` at rest (0.35). The disc and glyph dim
  separately, and the rest contrast is not measured. The hover state is not captured either.
- H4. The 2 px ring's contrast against the real container is unmeasured. 8.87:1 against band is an assumption.
- H5. The effective landing width is unmeasured. The ID values above are model values.

Not examined:

- Runtime: nothing here was run. No capture, tree dump, key test or pointer trace.
- Themes: only deep-night tokens were read. Other `Style.backend` values were not.
- Sizes: the four library steps and the desktop's `Theme.iconXl` only.
- Screen reader and keyboard verdicts: a11y-audit. Motion timing verdict: review-animations.
- Desktop call sites: the four desktop files listed by grep (PopoutRow, ColorPickContent, DashboardTab, MediaTab), not the whole desktop.

Evidence split: source-reviewed, every row above. Runtime-exercised, none. Owner-accepted, none.
