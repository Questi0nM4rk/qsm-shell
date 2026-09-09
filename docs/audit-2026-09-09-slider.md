# Slider audit 2026-09-09 (ui-audit + ux-audit)

Captures and tree dumps referenced below lived in the session scratchpad and were not kept; the tables carry the measured values.

Target: the `level` and `osd-slider` scenarios (`previews/units/Slider.qml`
hosting `qml/QsmShell/Components/Slider.qml`), theme `deep-night`.

Design sources used as "expected": `docs/components/Slider.md`, the approved
design record (session scratchpad `slider-design.md`), `tokens/deep-night.json`,
the **Component laws** section of `AGENTS.md`, `qml/QsmShell/Style/Motion.qml`,
and the two rubrics (`ui-audit/references/rubric.md`,
`ux-audit/references/heuristics.md`).

**No live window was opened.** The owner's `LivePreview` for `level` (pid
571691) was running for the whole audit, so every number below comes from the
offscreen capture pipeline and from three offscreen QtTest probes. Live-only
checks are under **Needs human trial** with an exact script.

## Standing owner rulings — not findings

`_wheelNotch: 120` and `z: 1` as literals; the position animation removed (not
shortened) under `Style.reducedMotion`; Qt's absolute press-jump on grab; hit
target = `Style.controlHeightSm` across the axis plus shadow slack when raised;
the a11y increase/decrease route silent to `moved()`/`committed()`.

## Measurement environment

- Offscreen (`QT_QPA_PLATFORM=offscreen`), scene 800x720 for both scenarios,
  `QSG_RHI_BACKEND=opengl` for the captures and `QT_QUICK_BACKEND=software`
  for the probes. `Style.backend` is null, so every value resolves to
  `tokens/deep-night.json`; `Style.reducedMotion` is **false** (probe 1 `ENV`),
  so the position `Behavior` is live and "no animation" would be a real
  finding, not a disabled token.
- Every rendered pixel sampled from the two PNGs came back as the **exact**
  token hex (`#382A48`, `#C5A5E9`, `#F6F1F9`, `#180F20`, `#B0ACB2`, `#1C0E27`),
  so no opacity or shader stack shifts colour. Contrast ratios were therefore
  computed on a synthetic token strip (`swatch.png`, `swatch2.png`) and apply
  verbatim to the rendered scene.
- **The offscreen pipeline does not rasterise `SvgIcon` glyphs**: `level.png`
  @520,364 and `osd.png` @372,436 both read background `#1C0E27` where a glyph
  belongs. Pipeline, not a finding. Everything glyph-shaped is judged live only.
- Motion tokens read from `Motion.qml`: `fast` 180, `press` 80, `micro` 130,
  `standardEasing` `Easing.OutCubic`.
- The unit does not set `fillLead`, so `fill === fillLead` in both scenarios
  and `gradient` resolves to `null` (`Slider.qml:377`). The two-stop lead ramp
  is dead in both scenarios — see UI-9 and **Not examined**.

## State-space map (ux deliverable #1)

Every row was visited. `probe`, `probe2`, `probe3` are the three log files.

| state | scenario | how reached | evidence |
| --- | --- | --- | --- |
| rest, value .82 | level | capture | `level.json`, `level.png`, `crop-level-thumb-z6.png` |
| rest, value .82 | osd-slider | capture | `osd.json`, `osd.png`, `crop-osd-thumb-z6.png` |
| hover, thumb | level | `mouseMove` onto the thumb | `probe.log` STATE hover |
| hover, track far end | level | `mouseMove` x=4 | `probe2.log` REACH |
| hover, passive glyph slot | level | `mouseMove` x=width−10 | `probe2.log` REACH |
| hover, control top edge | level | `mouseMove` y=1 | `probe2.log` REACH |
| hover / press / emphasized | osd-slider | pointer + property | `probe2.log` COLOUR |
| pressed, mid-drag | level | `mousePress` + 4 `mouseMove` | `probe.log` RESP |
| pressed, vertical, at bottom | osd-slider | `moveTo(0)` + `mousePress` | `probe.log` VSHADOW |
| at minimum / maximum | both | `toMinimum()` / `toMaximum()` | `probe2.log` BOUND |
| keyboard focus (ring) | level + vertical | probe takes focus, then Tab | `probe.log` STATE tab |
| pointer focus (no ring) | level | `mouseClick` on the track | `probe.log` STATE click-focus |
| disabled | level | strip `state`→disabled | `probe.log` h-disabled, DISABLED |
| raised / flat | level, osd | strip `shape` | `probe.log` h-sm-raised, `probe3.log` EMPH |
| thickness sm / md / lg | level | strip `thickness` | `probe.log` h-sm/h-md/h-lg |
| glyph on / off / start / end | level | strip `glyph`, `glyph position` | `probe.log` h-sm-noglyph, h-sm-glyphstart |
| thumb readout on / off, sm/md/lg | level, osd | strip `thumb content` | `probe2.log` THUMB |
| orientation flipped at runtime | level | strip `orientation` | `probe.log` v-sm-flat |
| wheel on (3x40 = 1 notch) | level | `mouseWheel` x3 | `probe.log` WHEEL |
| wheel off | — | source-verified `Slider.qml:582` | not exercised |
| RTL (mirrored) | level | `LayoutMirroring.enabled` | `probe2.log` RTL, `probe3.log` SLOT |
| reducedMotion | level | probe installs a `reducedMotion` backend | `probe3.log` RM |
| slot button press (osd) | osd-slider | `mouseClick` on the IconButton | `probe.log` OSD |

## Responsiveness (the design record's MUST) — PASS

Measured with no `tryCompare` anywhere; every read is immediate.

- `mousePress` at fraction 0.30: `handle.x` **66**, expected `leftPadding + 0.30 * 220` = **66**. Delta 0.
- Four `mouseMove`s at 0.50 / 0.70 / 0.90 / 0.10: `handle.x` **110 / 154 / 198 / 22**, expected **110 / 154 / 198 / 22**. Delta **0** after every single move, `_paintedPosition === visualPosition` throughout.
- Arrow key: `keyClick(Right)` read immediately gives value 0.10 → **0.15** and `handle.x` 22 → **33**, painted == visual.
- Direct route call: `_hostDriven` is **false** the instant `stepBy(5)` returns and **true** after one frame; same for `moveTo` (`probe2.log` HD).
- Host write (`slider.value = 0.20` from the probe acting as host) **does** animate: immediately `painted 0.15` vs `visual 0.20`; at 90ms `painted 0.192` (OutCubic predicts 0.194 — easing direction and shape confirmed); settled after `Motion.fast + 60` at `painted == visual == 0.20` and `handle.x` 44 = expected 44.
- Under `Style.reducedMotion` the same host write lands with `painted == visual` immediately (`probe3.log` RM), i.e. the animation is removed, not shortened.

## ui-audit findings

| id | pass | element | evidence (measured) | expected (source) | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| UI-1 | 4 colour | `osd-slider` empty track | `trackColor` `#180f20` (`previews/units/Slider.qml:67`, `Qt.darker(Style.surface, 1.35)`); contrast vs preview background `#1c0e27` **1.01:1**, vs the real backdrop `surface` `#21142b` **1.06:1** (`swatch.png`); `crop-osd-thumb-z6.png` shows no locatable track cap above the thumb | rubric Pass 4 wants ≥1.2:1 between adjacent surfaces and ≥3:1 for an essential UI element; `docs/components/Slider.md` `disabled(dims, still reads)` implies the extent reads at full strength | the unfilled remainder of the OSD track is invisible on both plausible backdrops, so "how much is left" cannot be read; the fill looks like a bar floating on the surface | **major** |
| UI-2 | 4 colour | `osd-slider` raised thumb at rest | thumb `#b0acb2` (`raised && !active`, `Slider.qml:75`) vs its own fill `#c5a5e9` = **1.06:1**; vs the empty track above it **8.32:1**; only separator is `sliderThumbShadow` 2px at `rgba(0,0,0,.45)`. `crop-osd-thumb-z6.png` separates the two by HUE (grey on lavender) while the luminance ratio stays 1.06, so the boundary survives a colour-normal eye and fails the rubric | the same line's own comment: the thumb default is "the lightest thing on the surface, which is what makes it read as raised out of the track"; rubric Pass 4 ≥3:1 for an essential UI element | at rest the raised thumb is DARKER than the fill it sits on, so its fill-side half has no edge; it only becomes `#f6f1f9` (1.90:1 vs fill, 11.85:1 vs track) once `active` | **major** |
| UI-3 | 4 colour | `level` (flat) state colours | rest / hover / press / `emphasized` all paint thumb `#f6f1f9`, fill `#c5a5e9`, track `#382a48` — identical (`probe2.log` COLOUR, `probe3.log` EMPH). Adjacent-state colour ratio **1.00:1** | rubric Pass 4: adjacent states distinguishable by ≥1.2:1 | a flat slider has no state colour at all; the entire state vocabulary is the thumb scale (see UX-1) | minor (root cause of UX-1) |
| UI-4 | 3 geometry | vertical raised thumb shadow | vertical, raised, glyph off, `moveTo(0)`: control h **180**, shadow bottom **182** (overflow **+2**), `shadow.y` 4 while pressed → overflow **+4** unscaled. Horizontal raised: overflow **−0.56** (contained). `_thumbSpan` adds `sliderThumbLift*4` to `_crossSize` = the WIDTH (`Slider.qml:268,272`), while the shadow always drops along `y` (`Slider.qml:411`) | the `_thumbSpan` comment itself: "The size a component asks for has to include what it paints"; `AGENTS.md` law "The width a component asks for must include the inset it then gives away" | on a vertical slider the shadow drops along the MAIN axis, which nothing pads, so it paints outside the control; the 8px of cross-axis slack it bought is spent where nothing needs it | **major** |
| UI-5 | 2 spacing, `source-conflict` | main-axis size vs slot padding | glyph on: `level` track **232** of 260 (−11%); glyph off: **260**. `osd-slider` track **136** of 180 (−24%), travel 104 not 148, so one unit is **1.04px** instead of 1.48px | `AGENTS.md` law "The width a component asks for must include the inset it then gives away" (ListRow) **vs** `slider-design.md` ("`before`/`after` … become padding like TextField") and the precedent `TextField.qml:149-151`, where `naturalWidth` is likewise the TOTAL and the slots eat it | `Style.sliderLength` names the control, not the track, so slot content shortens the travel; two sliders in one column with and without a glyph do not share a travel axis. Owner rules which source wins | minor |
| UI-6 | 4 colour | component-default track | `Style.surfaceHover` `#382a48` vs `background` `#1c0e27` **1.40:1**, vs `surface` `#21142b` **1.33:1** (`swatch.png`); `crop-level-thumb-z6.png` shows it as a faint plum bar | rubric Pass 4 ≥3:1 for an essential UI element | above the 1.2 visibility floor but well under 3:1 on either backdrop; `tokens/deep-night.json` has no colour that gives a track ≥3:1 on both, so this is a token gap, not a typo | minor |
| UI-7 | 5 typography | `thumbContent` at `thumbSize` 12 | handle **12x12**, content **16.688x14** → overflow **4.688 x 2 px**, `anchors.centerIn` spills it symmetrically over the track (`probe2.log` THUMB sm). Fits at md (−15.3/−18) and lg (−23.3/−26) | `docs/components/Slider.md` "the reading inside the thumb, which only has room for it once the thumb is a control-height one" (the unit's own comment, `previews/units/Slider.qml:50-51`) | recorded as a fact per the audit brief: the strip lets `thumb content` be on while `thickness` is `sm`, which is a state no real host builds — the same class as a magnifier on a password field | minor |
| UI-8 | 1 structure | focus ring on `osd-slider` | ring rect = the control rect **40x180 @(53,0)**, radius 20, border 1, `#c5a5e9`; the `after` IconButton is **36x36 @(55,144)**, entirely inside it (`probe.log` osd-rest, STATE vertical ring) | rubric Pass 1: a container's treatment must sort every element it encloses | a focused slider draws its ring around a second, separately focusable target; on `level` the ring likewise encloses the passive 20px glyph | polish |
| UI-9 | 4 colour | `fillLead` two-stop ramp | `fill === fillLead === #c5a5e9` in both variants, so `gradient` is `null` (`Slider.qml:377`, `probe2.log` DEFAULT); the unit declares no `fillLead` control | the brief for this audit asks specifically for "the contrast of the fill against the track at both ends of the gradient"; `Slider.qml:66-70` documents the ramp as a supported look | a public, documented look has no proof harness in either scenario, so its lead-end contrast is unmeasurable here | minor |

## ux-audit findings

| id | check | interaction | evidence (measured/traced) | expected (source) | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| UX-1 | 2 affordance & feedback | hover and press on `level` | thumb 12px → hover `scale` 1.08 = **12.96px** (growth **0.96px**); press `scale` 0.94 = **11.28px** (**−0.72px**); no colour moves (UI-3). At md/lg the same 8% is 2.56 / 3.2px | owner interaction law "growth not tint, visible response"; heuristics Check 2 "every input event gets a visible answer" | the plain reading rail answers hover with under one pixel of thumb diameter and nothing else; the cursor change is the only reliable cue, and it is a live-window fact | **major** |
| UX-2 | 2 affordance & feedback, `source-conflict` | press on the thumb | `handleScale` **0.94** while held (`probe.log` STATE press), and simultaneously `sliderThumbShadow.y` **2 → 4** (`Slider.qml:411`) | `docs/components/Slider.md` states `press(thumb grows + lifts)` **vs** `StateLayer.qml:43` `pressScale: 0.94`, which `Slider` does not override | the two press cues contradict each other: the thumb shrinks 6% while its shadow says it rose. Owner rules whether the doc or the default moves | **major** |
| UX-3 | 3 target ergonomics / 6 vocabulary | press inside the slot padding | `level`: press at x=250 (inside the 28px `after` padding) → value **0.56 → 1**, `committedValue` **1** (`probe.log` HIT). `osd-slider`: click the slot IconButton → value **0.82 → 0** by `toMinimum()` and `committedValue` stays **0.82**, so the slider never grabbed (`probe.log` OSD) | heuristics Check 6: one input, one meaning class across surfaces | the same slot region is a real control on the OSD and a jump-to-maximum strip on `level`, because a passive glyph does not consume the press. Pressing a decoration slams the level to the bound | minor |
| UX-4 | 6 vocabulary | wheel on a plain rail | the unit gives `wheelUnits: Style.sliderKeyboardUnits` (5) to BOTH variants (`previews/units/Slider.qml:61`; `probe2.log` DEFAULT level `wheelUnits=5`) | `slider-design.md`: `wheelUnits` defaults to 0, "0 = wheel off; OSD passes 5", "a seek bar wants a deliberate pointer; a volume bar is something you nudge" | the reading rail takes the wheel by default in the preview, so scrolling a popout that contains one changes the value. The component default is correctly 0 (`Slider.qml:60`) | minor |
| UX-5 | 6 vocabulary | RTL | `mirrored=true`: axis mirrors correctly (fill pinned right, right edge 232; `Right` **decreases** 0.82 → 0.77), but the glyph slot stays at **x=240** and `leftPadding/rightPadding` stay **0 / 28** — identical to LTR (`probe3.log` SLOT) | `Slider.qml:83-86`: "`before` and `after` sit at the ends ALONG the axis"; `slider-design.md` lists RTL as inherited from Qt | the slots are assigned by physical side while `before`/`after` are axis-relative, so under RTL `after` sits at the LOW end and the glyph's meaning silently flips | minor |
| UX-6 | 2 affordance & feedback | `emphasized` on a flat slider | flat: `emphasized` false → true flips `active` but leaves thumb, fill, track, `scale`, handle size and shadow byte-identical (`probe3.log` EMPH flat rest vs flat emphasized). Raised: thumb `#b0acb2` → `#f6f1f9`, ratio **2.01:1** | `Slider.qml:87-89`: "The consumer can force the emphasised look while the value is being changed from somewhere other than this control" | a documented public property and the public readonly `active` have zero painted consequence unless `raised`, and `level` — the variant a popout uses — is flat | minor |

## Verified conforming (measured, no finding)

- **Thumb centred on the track**, both orientations, all three thickness levels: `level` control 260x32, track y 362..366 (centre 364), thumb 358..370 (centre 364); md/lg thumb `y` backs out to exactly 0 once the hover `scale` is removed; `osd` thumb x 356..388 in a 352..392 control.
- **Fill runs from `from` to the thumb centre**: `level` fill 186.4 wide, thumb centre at 186.4 (`_thumbOffset + thumbSize/2`); `osd` fill top 34.72 = thumb centre 34.72.
- **Vertical fill grows from the bottom**: `osd` fill bottom = track bottom 410 at every value.
- **The half-thumb fill stub is always hidden** (one of the two deliberate items): at value 0 the fill is 6px and the thumb spans 0..12; at value 1 the fill is 226 of 232 and the thumb spans 220..232. Same in vertical (6 of 152, thumb covers). Nothing accent-coloured shows at either bound.
- **1% snapping** (the other deliberate item): pointer drag lands exactly on 0.30 / 0.50 / 0.70 / 0.90 / 0.10; `stepSize` 0.01, `snapMode: SnapAlways`.
- **Hit region = control bounds**: press 10px above the 4px track (y=4) grabs; press on the control's top edge (y=0) grabs. Cross-axis hit **32** (`controlHeightSm`) against a painted thumb of **12** on `level` and **40** against **32** on `osd` — both over the WCAG 2.5.8 24px floor and the 32px comfortable mark.
- **Slot padding**: empty slot is 0x0 and reserves nothing (`h-sm-noglyph` padR 0, track 260); a filled slot reserves `implicitWidth + slotGap`, measured gap track→glyph **8** = `Style.space2` in both scenarios and both slot ends.
- **Keyboard arithmetic exact**: Right/Left ±0.05 (`sliderKeyboardUnits` 5 x 0.01), PageUp/PageDown ±0.20, End → 1, Home → 0, off-axis Up ignored, Home at minimum is a silent no-op (no `moved`, no `committed`).
- **Wheel accumulation**: 40 → 40 → 120 fires exactly one unit step (+0.05) with one `moved` and one `committed`; direction reversal resets the accumulator to 0 rather than cancelling into it.
- **`committed` timing**: press on the thumb with no movement emits nothing and leaves `committedValue` alone; a track jump emits `moved` on PRESS and `committed` on RELEASE, then `committedValue` updates. One `committed` per key that moved.
- **`committedValue` is not bound to `value`**: it read 0.42 in both capture trees while `value` was 0.82.
- **Disabled**: control `opacity` **0.35** = `opacityDisabled`; press does nothing; `stepBy`, `moveTo`, `toMinimum` all return false; `hovered` stays false; all four `actions` report `enabled: false`. Dimmed fill vs dimmed track still separate at **1.92:1** (`level`) / **2.13:1** (`osd`), so "still reads" holds for the reading — the thumb is the part that stops (dimmed thumb vs dimmed fill **1.04:1**).
- **Focus**: Tab sets `visualFocus` and paints the ring at exactly the control rect (260x32 r16 / 40x180 r20, border 1, `#c5a5e9`); a click focuses without a ring. Ring vs background **8.70:1** (accent on `#1c0e27`).
- **Radii all derived**: track `(vertical ? w : h)/2` → 2 / 16 / 20, fill inherits, thumb `w/2`, ring `focusRadius` (`Slider.qml:455`). No literal in the inventory.
- **Thumb readout legibility** on the OSD: `#1c0e27` on `#b0acb2` = **8.23:1**, and **16.53:1** once the thumb goes active. 12px bold, `Style.textSm`.
- **Actions**: four, in order `Increase, Decrease, Minimum, Maximum`, and the a11y `increase()` route moves `value` by one unit while emitting neither `moved` nor `committed` (standing ruling).
- **`_paintedPosition` orientation dependency works**: `visualPosition` 0.18 after a runtime flip to vertical, painting from the bottom.

## Where each fix lands

| id | lands in | note |
| --- | --- | --- |
| UI-1 | `previews/units/Slider.qml:67` | the unit's `Qt.darker(Style.surface, 1.35)` override; the component default is UI-6 |
| UI-2 | `qml/QsmShell/Components/Slider.qml:75` | the `thumbColor` default, or the unit states its own |
| UI-3, UX-1, UX-6 | `qml/QsmShell/Components/Slider.qml` | one root cause: nothing but `scale` answers a state on a flat slider. Owner picks the cue (thicker/lighter fill on `active`, a track lift, a larger `hoverScale` for a thin thumb) |
| UI-4 | `qml/QsmShell/Components/Slider.qml:268-282` | the lift slack has to go on the axis the shadow drops along |
| UI-5 | owner ruling first | law vs `TextField` precedent; if the law wins, `implicitWidth/Height` add the padding instead of `Math.max`-ing it |
| UI-6 | `tokens/deep-night.json` | no existing colour reaches 3:1 as a track on both `background` and `surface` |
| UI-7 | `previews/units/Slider.qml:135-159` | either bind `showThumbContent` to a thumb big enough, or drop the combination from the strip |
| UI-8 | no fix proposed | ring = control is correct; the finding is that a slot can hold a second target |
| UI-9 | `previews/units/Slider.qml` | a `fillLead` control group, so the ramp has a harness |
| UX-2 | doc or component | `docs/components/Slider.md` says grows; `StateLayer.qml:43` says 0.94. One of them moves |
| UX-3 | `qml/QsmShell/Components/Slider.qml` | exclude the slot rects from the press area, or document that a slot must consume its own press |
| UX-4 | `previews/units/Slider.qml:61` | `wheelUnits: root.decorated ? Style.sliderKeyboardUnits : 0` |
| UX-5 | `qml/QsmShell/Components/Slider.qml:288-295, 325-340` | pad and place the slots by AXIS end, not by physical side |

## Hypotheses (not measurable offscreen — labelled as such)

- **Fractional item positions.** `handle.x` is 450.4 / 180.211 / 18.72 in the
  dumps. These are value-derived and inherent to a continuous position, and the
  z6 crops show no 1px smear that a static misalignment would leave, so this is
  a rendering-quality hypothesis, not a finding. It needs a live window at
  scale 1.2 to judge.
- **A runtime orientation or mirroring flip animates the thumb across the
  track** (`v-sm-flat` caught `painted 0.318` against `visual 0.18`; RTL caught
  0.314 against 0.18). That is the motion rule working as written — the flip is
  not a gesture — but in the live window, clicking the `orientation` control
  will read as the thumb sliding for 180ms. Worth the owner's eye before it is
  called correct.
- **Hover reaches the whole control**, so the thumb grows when the pointer is
  200px away from it, over a passive glyph. Consistent with press-anywhere-jumps
  and with `active` being control-wide; listed here rather than as a finding
  because it has no failure scenario I can name.
- **`fill` vs `thumb` at 1.90:1** when the thumb is active and sitting over the
  fill. The thumb always keeps one high-contrast edge (11.85:1 against the empty
  track on its other side), so this is a soft-edge hypothesis, not a legibility
  failure.

## Needs human trial (exact script)

The owner's `LivePreview` was open, so none of these were exercised. Each needs
one live window per scenario.

1. **Glyph rasterisation and icon weight.** `npm run preview -- level`, then
   `npm run preview -- osd-slider`. Judge: does the `volume` glyph at
   `Style.iconMd` (20px) read at `textMuted` `#b6a8c2` beside a 4px track, and
   does the OSD's `IconButton` glyph at `#f6f1f9` read against `background`?
   Offscreen paints neither.
2. **UX-1 in the hand.** Open `level`, sweep the pointer slowly across the
   track without pressing, eyes on the thumb. Question: is 0.96px of growth an
   answer, or is the cursor change doing all the work? Then press and hold: does
   the 6% shrink read as "picked up" or as "pushed away"? This is the call that
   settles UX-1 and UX-2.
3. **UI-1 in the hand.** Open `osd-slider` and look for the top of the track
   above the thumb. If you cannot see where the track ends, UI-1 is confirmed at
   `major`. Then flip `shape` to flat and back: with the shadow gone, is the
   thumb still separable from the fill (UI-2)?
4. **UI-4 in the hand.** Open `osd-slider`, drag the thumb to the very bottom
   and hold. Watch for the shadow spilling past the control's bottom edge onto
   whatever sits under it. Then flip `glyph` off, which removes the 44px of
   bottom padding that currently absorbs the spill, and repeat.
5. **Wheel under a real wheel.** `AGENTS.md` records that synthetic
   `mouseWheel` never reaches a `WheelHandler` under this Qt6 Wayland QPA, so
   the wheel was proved offscreen only. On `level`, scroll a real wheel one
   notch and confirm one 0.05 step and one readout change, then set
   `wheel → off` and confirm nothing moves (UX-4's consequence).
6. **UX-3 in the hand.** On `level`, click directly on the volume glyph. If the
   value slams to 100%, UX-3 is confirmed as a live behaviour and not a probe
   artefact.
7. **Cursor shape.** `Slider.qml:464` gives the whole control
   `PointingHandCursor` when enabled and `ArrowCursor` when disabled; the OSD's
   slot `IconButton` states its own. Confirm the disabled slider shows an arrow
   and that the cursor does not change over the passive glyph on `level`.

## Not examined

- **Pass 7, multi-monitor.** Not applicable: these are library units in an
  800x720 offscreen scene, not a shell surface claiming an output. No per-screen
  claim is made either way.
- **Pass 6 mid-flight capture.** Motion was judged from the position timeline
  (`painted` sampled at 0, 90ms, 240ms against `visual`) and from the token
  durations at `Slider.qml:411,415` and `:425`. The press lift (80ms) and the
  thumb colour transition (130ms) were confirmed to settle but were not sampled
  mid-flight; `grim` stepping cannot resolve either.
- **The `fillLead` gradient** (UI-9): neither variant sets it, so the ramp's
  orientation branch (`Slider.qml:344-352`) and its lead-end contrast are
  unproven.
- **`before` and `after` populated at the same time.** Every state visited had
  exactly one slot filled; the two-slot case, and therefore the sum of both
  paddings against `sliderLength`, was not measured.
- **A range wider than 0..1.** `from`/`to` stayed at the defaults, so the
  `stepSize`-vs-bounds saturation recorded in `docs/components/Slider.md` was
  not re-measured here.
- **`focusColor` override.** `StateLayer.focusRadius` is passed but
  `focusColor` is not, so the semantic-colour path that `TextField` needed has
  no slider equivalent to audit.
- **Wheel with `wheelUnits: 0`** — source-verified at `Slider.qml:582`, not
  exercised.
- **Live window.** Nothing in this audit was seen on a compositor.

## Evidence paths

All under
`/tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/audit-slider2/`:

- Captures and trees: `level.png`, `level.json`, `osd.png`, `osd.json`.
- Crops (zoom 6): `crop-level-thumb-z6.png`, `crop-osd-thumb-z6.png`,
  `crop-osd-bottom-z6.png`.
- Contrast references: `swatch.png` (11 token and 0.35-composite columns at
  x=20,60,…,420), `swatch2.png` (thumb-readout pairs).
- Probes and logs: `tst_probe.qml` / `probe.log` (environment, responsiveness,
  keys, wheel, hit region, OSD slot button, state enumeration, vertical shadow,
  hover/press/focus), `tst_probe2.qml` / `probe2.log` (variant defaults,
  `_hostDriven` window, both bounds, `committed` timing, hover reach, RTL, thumb
  overflow, state colours), `tst_probe3.qml` / `probe3.log` (`emphasized` on a
  flat slider, RTL slot side, `reducedMotion`).
- Probe invocation:
  `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QML_XHR_ALLOW_FILE_READ=1 /usr/lib/qt6/bin/qmltestrunner -import <repo>/qml -input <scratch>/tst_probe.qml`
