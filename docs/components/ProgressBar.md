# ProgressBar

A thin determinate or indeterminate progress line; it shows a fraction or ongoing work and takes no input.
states: determinate fill by clamped value and indeterminate travelling band; disabled blends track and fill opaquely through `Style.disabled`.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: no role of its own; the surface owning the task announces progress.
size: fixed track thickness with pill radius; the indeterminate band is three tenths of the width; the bar fills its host on the main axis.
tokens: trackThickness, accent, overlay and disabled colour blending; no local colours or measurements.
motion: fast width settling on value change and a looping sweep while indeterminate and visible; reduced motion lengthens the loop period.
not designed: metering a level, staging steps or labelling; use Meter, Stepper content or Prose for those.

## UIX audit

Evidence: source-reviewed only. No Workbench session, preview, capture or item-tree dump was run.
Live geometry: not reached. Every number below is arithmetic on `tokens/deep-night.json` (the only
theme read) or a WCAG 2.x ratio computed from those hex values. Nothing here is runtime-exercised or
owner-accepted.

Accessibility criteria (platform exposure, colour-only meaning, focus, reduced-motion conformance)
are a11y-audit's; run it for this surface.

### Purpose and consequence

It shows how far a known process has got, or that unknown work is running, and takes no input. A
determinate bar's length is trusted, so an indeterminate one must not look like a slow determinate one
(ProgressBar.qml:9-14).
`Spinner.qml:10` and `Meter.qml:8` name it as the sibling they defer to.

### Expected controls and states

Properties: `value` (0..1, clamped at ProgressBar.qml:25), `indeterminate`, `fill`, `trackColor`,
`thickness`, and `enabled` inherited. No signals, no functions, no actions; the unit declares
`events: []` and `actions: []` (workbench/units/ProgressBar.qml:46-48).

| State | Implemented by | Status |
| --- | --- | --- |
| determinate, value 0, 0.5, 1 | lead width fraction, ProgressBar.qml:37 | implemented |
| indeterminate | sweep, ProgressBar.qml:52-72 | implemented |
| disabled | `Style.disabled` on track (:29) and fill (:40, :59) | implemented |
| completing (finish the cycle, then stop) | no finish phase; the sweep is dropped at once | absent, see proposals |
| rest, hover, press, focus | not applicable: no pointer, no focus | n/a |
| empty, long content, error | not applicable: no content, no failed state | n/a |

### Routes

- Pointer: none. The file has no handler and no MouseArea; the bar takes no events.
- Keyboard: none. Not a tab stop (no `activeFocusOnTab`, no key handler).
- Wheel: none; wheel passes through to the host.
- Focus: none.
- Accessibility: no `Accessible` attached property is set (whole file). The owning surface announces
  progress by design (ProgressBar.md line 8). See hypothesis H1.
- Cancellation: a host stops by setting `indeterminate: false` or `visible: false`; the sweep also stops
  when `root.visible` is false (ProgressBar.qml:70).

### Sizes, empty and long content, failure

- Height: `Style.trackThickness`, 4 px (tokens/deep-night.json; ProgressBar.qml:23, 27).
- Width: not set. `implicitWidth` is absent (ProgressBar.qml:27), so the natural width is 0 and the
  bar fills its host (line 9 of this record). The unit's host is 380 px (`controlWidth`, tokens:99).
- Radius: height / 2, so 3 px at md (ProgressBar.qml:28).
- Indeterminate band: 0.3 of the track width, 114 px at 380 px (ProgressBar.qml:56).
- Content: none. Failure: no failed state; an unguarded `value` is hypothesis H2.

### Visual roles and palette pairs

Roles from source: fill `Style.accent` (ProgressBar.qml:21, see PB-1), track `Style.overlay`
(ProgressBar.qml:22). `overlay` is the ladder's inactive-track role (AGENTS.md, surface ladder table).

Computed WCAG 2.x ratios, deep-night hex values:

| Pair | Ratio | Needed | Result |
| --- | --- | --- | --- |
| fill `#d9b4ea` on track `#4c4357` | 5.19 | 3 (1.4.11) | pass |
| track `#4c4357` on band `#271e30` | 1.71 | 3 (1.4.11), if the empty track is needed to read progress | SC1 |
| track `#4c4357` on surface `#3b3145` | 1.31 | as above | SC1 |
| disabled fill on disabled track | 1.87 | exempt (inactive component) | n/a |
| disabled track on band | 1.23 | exempt | n/a |

Disabled colour: `Style.disabled` blends toward band by `opacityDisabled` 0.35 (tokens:78;
Style.qml:107-112), opaque, with no opacity on a composite. This matches the AGENTS rule.

### Motion and reduced-motion form

- Determinate lead: `Behavior on width`, NumberAnimation, `Motion.fast` 180 ms (tokens:56), 80 ms
  under reduced motion (Motion.qml:56), `Motion.moveEasing` InOutCubic (Motion.qml:128; ProgressBar.qml:45).
- Indeterminate sweep: `XAnimator`, period `Motion.spin * 2`. `Motion.spin` is 900 ms in tokens:73, so
  the sweep is 1800 ms normal. Under reduced motion `Motion.spin` is 1800 ms (Motion.qml:108) and the
  sweep is 3600 ms (ProgressBar.qml:65). Travel is 1.3 times the track width, 494 px at 380 px: 274 px/s
  normal, 137 px/s reduced. Loops infinite, InOutCubic at both ends.
- Reduced motion: the loop period lengthens, as AGENTS requires. The determinate settle
  is removed, not shortened (PB-4, fixed).
- The lead animates `width`, which review-animations standard 7 names (proposal 8).

The timing verdict is review-animations'. The values above come from the tokens only.

### Pointer geometry

- Input shape: none. The Rectangle declares no pointer handler and accepts no mouse input. Painted
  size: 6 px thick and the host's width (380 px in the unit).
- D, W, ID: not applicable; the bar is not a target. Hypothetical, if a host used it as a seek
  control: perpendicular approach from 40 px away (assumed origin, not measured). Width model:
  Shannon, with W measured along the motion axis, which for a perpendicular approach is the
  vertical extent.
  - Painted 6 px as the input: ID = log2(1 + 40/6) = 2.94 bits; landing tolerance ±3 px.
  - 24 px input (the WCAG 2.5.8 floor cited in ux-audit): ID = log2(1 + 40/24) = 1.42 bits;
    landing tolerance ±12 px.
- Neighbouring interference: none from the bar itself. The host's neighbours are not examined.
- Corridor and timing: not applicable (not a popup).

### Findings

Defects, source-backed:

- **PB-1** (minor) `ProgressBar.qml:21`. The fill binds `Style.accent`, but the ladder gives the active
  part of a track `primary` (Style.qml:38, AGENTS.md table row `primary`), and accent is reserved for
  focus, selection and primary action, not passive metrics. Nothing shows in deep-night because
  `accent` and `primary` are both `#d9b4ea` (tokens:8, :10). The fault appears in any theme that
  separates them, where a passive reading takes the selection colour. Fix: `property color fill:
  Style.primary`. shared=false.
- **PB-2** (minor) `ProgressBar.qml:56` (`0.3`) and `:65` (`Motion.spin * 2`). AGENTS: "No numbers in
  a component" and definition-of-done item 6. The band share and the sweep period cannot be retuned
  by theme. Fix: move both into `Style` and `Motion` with tokens. shared=true (tokens/*, Style/*).
- **PB-3** (minor) `ProgressBar.qml:54` and `:70`. Neither the sweep's visibility nor its loop checks
  `enabled`, while the colour dims at `:59`. A disabled indeterminate bar keeps travelling at 274 px/s
  as though work is running. AGENTS: motion communicates state. Fix: gate the sweep on `root.enabled`
  (hide the band when disabled). shared=false.
- **PB-4** (minor, fixed: source-reviewed, load-checked; not owner-accepted) `ProgressBar.qml:44-46`. The `Behavior on width` is not gated by reduced motion.
  AGENTS says a one-shot position animation is removed under reduced motion, not shortened. The law
  text names sliders, so applying it to the lead is a reading. review-animations standard 8 asks for
  movement to be dropped. The lead still slides in 80 ms (Motion.qml:56). Fix: `enabled:
  !Style.reducedMotion` on the Behavior. shared=false.
- **PB-5** (polish, open: the mask's GPU cost is unmeasured and measuring is not allowed in this pass) `ProgressBar.qml:30` (`clip: true`, rectangular) with the sweep at `:52-58`
  (`radius: parent.radius`). At thickness 6 px the track's end is a 3 px radius. When the sweep's cap is
  1 px outside the start edge, the band spans ±2.24 px about the centreline at x=0 while the track spans
  0 px, so the band overhangs the rounded end for a few frames at entry and exit. Visible at zoom only.
  Fix: mask the sweep to the track silhouette, only if the layer cost is measured. shared=false.

Source conflicts:

- **SC1** AGENTS.md surface ladder makes an inactive track an `overlay` line of content (1.71:1 on band,
  1.31:1 on surface, computed above). WCAG 1.4.11 asks 3:1 for graphical parts needed to understand
  content. Whether an empty track is needed to read progress is the owner's ruling, not a fix.

Redesign proposals (taste, not defects):

1. Add a completing phase, as caelestia does (`StyledProgressBar.qml`, `updateIAnimState` and the
   `Completing` state): when `indeterminate` goes false the sweep finishes its cycle before the lead
   takes over. Today it is dropped at once (ProgressBar.qml:52-72).
2. Sweep easing: InOutCubic (Motion.qml:128) against caelestia's linear loop
   (`Easing.Linear`). The file's comment (ProgressBar.qml:67-69) argues for eased ends. Keep as
   documented unless the owner rules otherwise.
3. Set `implicitWidth` to a Style constant (ProgressBar.qml:27 sets only height). qml-ui says a
   reusable component sets both implicit sizes; today a host that omits width gets a 0 px bar. shared=true.
4. A size preset: AGENTS asks sized types to take `Style.size("<Type>", size)`. This type reads
   `Style.trackThickness` directly (ProgressBar.qml:23). shared=true.
5. In indeterminate mode the unit's value controls (unit:32-36) change nothing, as the component
   ignores `value` (ProgressBar.qml:18). Disable that group while `unknown`, or label it. shared=false.
6. The lead width is unrounded (ProgressBar.qml:37); qml-ui's integer-geometry rule would round it.
   Rounding steps the fill by 1 px, 0.26% of 380 px, and the rounded end is anti-aliased anyway, so the
   gain is doubtful.
7. The lead animates `width` (ProgressBar.qml:45), which review-animations standard 7 names. No cheap
   transform keeps the rounded end, so keep it and record.
8. If a host ever uses this bar as a seek target, the host must own a 24 px or larger input shape
   (1.42 bits against 2.94 at 6 px, the assumed 40 px approach above).

Hypotheses (unmeasured):

- **H1** The Rectangle exposes no role or value to the platform tree (whole file). A passive bar may
  read as nothing to assistive tech. a11y-audit decides.
- **H2** `value` is not guarded against NaN or undefined (ProgressBar.qml:25). `Math.min(1, NaN)` is NaN,
  which would make `width` NaN. Not measured.
- **H3** Below a lead of about 6 px (value under 6/380, about 0.016), the 3 px radius is wider than the
  lead and the end shape distorts. Not measured.
- **H4** The lead is anchored left (ProgressBar.qml:34) and does not mirror under a right-to-left layout.
  Not examined beyond source.

Not examined: runtime (no session, preview or capture), other themes (only `tokens/deep-night.json`
read), reduced-motion values through the real Style backend (formulas read, not run), keyboard,
focus and accessibility tree (a11y-audit), and the unit beyond its declaration and its controls.
