# StateLayer

The component that owns the five states; every interactive control forwards rest, hover, press, focus and disabled through it instead of inventing its own.
states: rest, hover, press, focus and disabled via hovered, pressed, focused and interactive; the response swells on hover and shrinks on press, and focus draws a one-pixel accent ring.
actions: enumerated `activate()` and a real tap share `clicked` on an unhosted, available, clickable layer; hosted templates own their activation. `hoveredEntered` reports genuine pointer entry; `clickable: false` keeps hover feedback while refusing press and click. Growth lands on the target and never grows a layout.
pointer: hand cursor while interactive and arrow otherwise; hover entry reports upward only while the pointer owns selection.
keyboard: none of its own; focused follows the host or parent focus and the ring shows whenever focus is held, however it arrived.
screen reader: none; the hosting control carries the role and name.
size: no footprint of its own; hover and press scales are factors and the focus radius follows the hosted body.
tokens: accent and the press and micro Motion set; `focusColor` carries a stronger semantic state so the ring never erases it.
motion: press response and micro ring settling with the standard easing; reduced motion shortens the durations.
expected: `manualHoverOverride` and `manualPressOverride` add host-supplied visual state, remain gated by availability, and never emit click or selection intent. Genuine pointer entry is reported independently of a held override. Template and geometry wiring follows caelestia `components/StateLayer.qml` and `components/controls/ButtonBase.qml`; the visual overrides are retained, but the native pointer fact remains separate to preserve selection intent.
not designed: content, layout or dismissal; it is feedback on a host that owns all three.

## UIX audit

Evidence: source-reviewed only. No live geometry tree, capture, run or test was taken, so every
pixel and timing figure below is computed from source values, not measured. No owner acceptance.

Sources read: `qml/QsmShell/Components/StateLayer.qml`, `workbench/units/StateLayer.qml`,
`qml/QsmShell/Style/Tokens.qml`, `Motion.qml`, `Style.qml`, `Interaction.qml`,
`tokens/deep-night.json`, the desktop call sites `shell/modules/bar/RailEntry.qml` and
`shell/modules/panel/PanelHandle.qml`, and caelestia `components/StateLayer.qml`. Not read:
`components/controls/ButtonBase.qml`, `tests/units/tst_StateLayer.qml`, the other desktop call sites.

### Purpose and consequence

The type makes a host's interactive body show the five states (rest, hover, press, focus,
disabled) and reports intent upward. When it fails, a control does not answer the pointer, or a
keyboard user cannot see where focus is.

### Controls, states and routes

Public surface: `host`, `interactive`, `clickable`, `target`, `hoverScale`, `pressScale`,
`hoverTint`, `focused`, `focusRadius`, `focusColor`, `manualHoverOverride`, `manualPressOverride`;
signals `clicked`, `hoveredEntered`; function `activate()`. The `actions` list holds one
"Activate" action that nothing in the component calls. No enum-driven size or variant exists.

| state | implemented | source |
| --- | --- | --- |
| rest | `response` 1, no paint unless `hoverTint` | l. 113, 115 |
| hover | growth to `hoverScale` (1.08) on the target; colour only through `hoverTint` (`Style.tone` lift 0.4) or a hosted body | l. 56, 113, 118 |
| press | colour only through `hoverTint` (lift 0.8) or host; scale only if `pressScale` is set (default 1); pressed comes from the tap or the host only | l. 59, 83, 118 |
| focus | 2 px accent ring outside the layer, concentric; keyboard only | l. 72, 147-162 |
| disabled | the layer stops answering and hides the ring; dimming is the host's (`Style.disabled`) | l. 81-83, 152 |

Routes:
- Pointer: `HoverHandler` gives a hand cursor when interactive and clickable, arrow otherwise
  (l. 164-168). `TapHandler` uses `DragThreshold` (l. 170-183). `hoveredEntered` fires on entry
  only while `Interaction.pointerSelects` is true (l. 106-108).
- Wheel: no handler takes it, so the wheel passes to ancestors. Source only.
- Keyboard: none of its own. The unit's Space and Return call `activate()` on the body.
- Focus: read from the host, or from the parent (see defect SL-1).
- Screen reader: none on the layer. The unit's body declares role Button and the name
  "State layer sample", a placeholder. a11y-audit owns the test.
- Cancellation: a drag past `DragThreshold` cancels the tap, so no `clicked`. `activate()` returns
  false when disabled, unclickable or hosted (l. 93-98). No reset path.

Sizes and content: the layer has no size of its own, so an unsized use has an empty input. The unit
sets 190 by 52 px (`Style.controlWidth / 2`, `Style.controlHeightLg`), which is not a `Style.size`
preset name. No content, so no empty or long state. No failure state applies.

Visual roles and palette pairs (source values from `deep-night.json`):
- Ring `accent` #d9b4ea on `band` #271e30: 8.87:1 computed. On `surface` #42394c: 6.07:1. The real
  neighbour is the host's ground, which this record cannot see; these are the pairs the ring can
  meet in the unit's ground.
- Hover tint: `surface` lifted by 0.4 (hover) and 0.8 (press) in `Style.tone` (Style.qml l. 126-138).
- Disabled: `Style.disabled` blends toward `band` by `opacityDisabled` 0.35, applied by the host.

Motion (the verdict is review-animations'): response 130 ms (`Motion.micro`), 80 ms when pressed
(`Motion.press`), `OutCubic`. Reduced motion gives 60 ms and 40 ms (`Motion.qml` l. 24, 26). The
scale itself does not depend on `reducedMotion` (see SL-C2 in the conflicts). The ring fades in over
130 ms and does not fade out (SL-4).

### Pointer geometry (modelled, not measured)

- Painted body (unit, action variant): 190 by 52 px, radius 12 (`Style.radiusMd`).
- Input shape at rest: the layer sits at (-2, -2) with 194 by 56 px, a 2 px halo per side.
- Hover: the body scales 1.08 about its centre. Painted: 205.2 by 56.2 px, so its edge moves 7.6 px
  per side horizontally and 2.1 px vertically over 130 ms. Input: 209.5 by 60.5 px, halo 2.2 px.
- Origin assumptions: the scale origin is the body centre (Qt default); the input origin is the
  layer's top-left in body coordinates; the label origin is the target centre.
- Weights: Shannon form, ID = log2(1 + D/W). No per-user weights and no human average.
- D: assumed 190 px, an adjacent body of the same width with no gap. This is a modelled distance.
- W: input width on the approach axis, 194 px at rest and 209.5 px on hover.
- ID: 0.99 bits at rest (log2(1 + 190/194) = 0.985), 0.93 bits on hover (0.931).
- Landing tolerance: 2 px beyond the painted edge at rest, 2.2 px on hover.
- Neighbour interference: two bodies closer than 4 px at rest (4.3 px on hover) share an input
  band. The unit has no neighbour, so none is measured.
- Trigger-to-panel corridor: not applicable, no popup.
- The ring extends 4 to 6 px outside the body but outside the input, so a pointer on the ring does
  nothing. That is correct for a focus mark, and the record notes it so no one takes the ring for a
  hit zone.

### Findings

Defects (source-backed; each cites its file and line):

- SL-1 (major, `qml/QsmShell/Components/StateLayer.qml` l. 72). For an unhosted layer, `focused`
  reads `(root.parent as T.Control)?.visualFocus`. The comment at l. 64-66 says a plain item follows
  its parent. In the unit the parent is a `Rectangle`, the cast gives null, and `focused` stays
  false while the body holds keyboard focus (`activeFocusOnTab`). What a person sees: Tab onto the
  sample and no ring appears. qsm-desktop works around the same gap by passing `focused:
  root.activeFocus` (`shell/modules/bar/RailEntry.qml` l. 144, `shell/modules/panel/PanelHandle.qml`
  l. 80). Fix: `property bool focused: _hosted ? (host.visualFocus ?? false) : (root.parent?.activeFocus ?? false)`.
  Shared: yes (the component file). Untested.
- SL-2 (major, `workbench/units/StateLayer.qml`, body `color:`; fixed, source-reviewed and load-checked, not owner-accepted). The body colour is
  `enabled ? Style.surface : Style.disabled(Style.surface)` and never reads `layer.hovered` or
  `layer.pressed`. `hoverTint` is off. What a person sees in the story: hover grows the sample by
  8% and changes no colour; press changes nothing. The component's own header (l. 6-13) says colour
  comes from the body through `Style.tone`. Fix: `color: enabled ? Style.tone(Style.surface, layer.hovered, layer.pressed, false, true, Style.accent) : Style.disabled(Style.surface)`.
  Shared: no (unit file). The body now reads `Style.tone` with `layer.hovered` and `layer.pressed`.
- SL-3 (minor, `StateLayer.qml` l. 175-181). The comment says a press that does not take focus clears
  the mark. The code clears only when `!root.focused` after release. A control that already holds
  keyboard focus keeps `focused` true, so `_pointerFocus` stays true. What a person sees: Tab to a
  control, click it, and the ring vanishes and stays off while focus stays. Fix: set
  `_pointerFocus = !root.focused` on press, so only a press that takes focus hides the ring, and keep
  the release clear. Shared: yes. Untested; the order of press and focus change in Qt is unverified.
- SL-4 (minor, `StateLayer.qml` l. 152 and 157-161). `visible` and `opacity` both follow the focus
  condition. `visible` goes false at once, so the 130 ms opacity Behavior never plays on loss: the
  ring snaps off. What a person sees: a snap, not a fade. The verdict is review-animations'. Fix:
  drop `visible` and let `opacity` carry the state, or bind `visible` to `opacity > 0`. Shared: yes.
- SL-5 (minor, `StateLayer.qml` l. 83 and 93-98). `pressed` reads only the tap or the host, and
  `activate()` never sets it. A keyboard press in an unhosted layer fires `clicked` with no pressed
  state. What a person sees: Space on the focused sample logs the intent and shows no press. Fix:
  add `press()` and `release()` functions, listed in `actions`, that drive an internal flag the
  key handler on the host can call, so keyboard and pointer share one route. Shared: yes.
- SL-6 (minor, `StateLayer.qml` l. 148-150 with the rule at l. 144-146). The ring is anchored to the
  layer, not to the target. With the unit's 2 px layer outset, the ring sits 4 px off the body edge
  (layer outset 2 px plus the stroke's 2 px), twice the `spaceTight` gap the comment states. A host
  that sizes the layer to its target gets the stated 2 px. What a person sees: the unit's ring floats
  further from the sample than the comment's rule. Fix: anchor the ring to the target, or state that
  the gap is measured from the layer. Shared: yes.

Source conflicts (the owner rules):

- SL-C1: the record says focus draws "a one-pixel accent ring"; the code draws `Style.spaceTight`
  (2 px in the default tokens, `Tokens.qml` l. 27, `StateLayer.qml` l. 155). The record needs to
  change, or the code does.
- SL-C2: AGENTS says reduced motion shortens durations and never removes a state response. qsm-uix's
  a11y guidance says reduced motion drops movement and keeps colour. Hover growth is a scale, so
  the two sources disagree. Ungated values: `Motion.qml` l. 46, `StateLayer.qml` l. 56 and 113.
- SL-C3: the record says the geometry "follows caelestia `components/StateLayer.qml`". Caelestia's
  file is a `MouseArea` overlay with an 8% state opacity, a press ripple and no scale, and no focus
  ring (l. 1-60 read). The hover scale is an owner decision (the header quotes it), not a
  caelestia pattern. The record claim needs narrowing. `ButtonBase.qml` was not read.

Proposals (taste and contract, not defects):

- Add a size or document that an unsized layer has an empty input. Desktop call sites size it, but
  the component does not say so.
- `StateLayer.qml` l. 148 uses a literal `* 2` for the ring reach (gap plus stroke). Name it from
  `Style` so the component keeps "no numbers".
- The unit's `implicitWidth: Style.controlWidth / 2` is a derived width, not a `Style.size` preset.
  The unit is the owner's judgement surface, so name the preset when the component gains one.
- An 8% state overlay with a press ripple, as caelestia uses, is a valid alternative to growth. The
  owner chose growth, so this is a note for the owner, not a finding.

Hypotheses (unmeasured, one line each):

- H1: a pointer aimed at the rest edge of a hovered body finds the edge 7.6 px further out after
  130 ms, so a fast aim at a corner can land on the gap. Not measured.

### Not examined

- No live geometry, capture, tree dump, run or test. Every figure is source arithmetic.
- Keyboard, focus and screen-reader behaviour in a running window (a11y-audit).
- Reduced motion, real timing and the ring's fade in a running window (review-animations).
- The other desktop call sites and their `hosted` or `target: null` use, beyond the two read.
- `Interaction.pointerSelects` in a list, since no list host was read.
- The stories in `workbench/stories.json` beyond the key `state-layer`.

Evidence level: source-reviewed. Runtime-exercised: none. Owner-accepted: none.
