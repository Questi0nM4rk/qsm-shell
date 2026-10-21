# ControlLabel

The one label element that names a control from outside; Field puts it above a text box and Slider wears it on any of four sides.
states: rest and disabled through `Style.disabled`; `clickable` true makes the control an action surface, off it is a caption.
actions: `activate(): bool` and its named `activate` Action share `clicked` with pointer, keyboard and accessibility activation when clickable, enabled and nonempty. Icon, text and required are properties; content inside a control belongs to the control itself.
pointer: a clickable label overflows a hit box of at least icon size around its footprint instead of growing it; a caption claims nothing.
keyboard: actionable labels alone join Tab/Backtab traversal; Enter, Return and Space activate once per press. Focus or availability/content loss cancels a held activation.
screen reader: actionable labels expose Button press and caller-owned `accessibleName` (defaults to text); passive labels remain supporting caption text. The required mark is a non-colour channel.
size: `sizeScale` from the owning control scales text, glyph and gap through the Style helpers; the hit box never moves neighbouring content.
tokens: textSm, iconSm, iconLg, space1, textMuted, danger, radiusSm and StateLayer; no local colours or measurements.
motion: StateLayer response only when clickable; no local animation.
expected: public, pointer, keyboard and accessibility activation share one guarded operation; disabled, caption and empty-label cases report no intent. Actionable labels are keyboard reachable without changing layout footprint; passive captions add no Tab stop.
not designed: input, validation copy or layout; use Field, the control itself or the host for those.

## UIX audit

Evidence: source-reviewed only. No Workbench session, capture, preview or test run. `tests/units/tst_ControlLabel.qml` was read, not run. Skills applied: ui-audit, ux-audit, a11y-audit (criteria left to it), qml-ui, review-animations (for the motion this type inherits from StateLayer). Sibling: caelestia has no caption label. The nearest bare-target pattern is `IconTextButton.qml`, whose body carries the colour; this type has no body, so its hover and press must come from StateLayer's `hoverTint` and `pressScale`.

### Purpose and consequence

Names a control from outside: a Field caption above a text box, a Slider label on one of four sides. When `clickable`, it is the one action on a slot or a line: reveal password, connect, Slider mute. If it fails, a caption that looks like a button does nothing, or a real action gives no sign that it was pressed.

### Expected controls and states

| Item | Expected | Implemented |
| --- | --- | --- |
| `text`, `icon`, `required`, `accessibleName`, `sizeScale` | properties | yes, `ControlLabel.qml:22-30` |
| `clickable` | makes it an action or a caption | yes, `:25` |
| `activate(): bool` and action `activate` | one guarded operation for pointer, keys and assistive tech | yes, `:34-42` |
| `clicked` | the intent signal | yes, `:32`, `:40` |
| rest | `textMuted` | yes, `:57` |
| hover | grows and changes colour | yes, `hoverTint` on the StateLayer (CL-2 fixed, source-reviewed, load-checked) |
| press | scales or changes colour | nothing (CL-1) |
| focus | keyboard ring only | yes, through StateLayer: `StateLayer.qml:152`, `:174-181` |
| disabled | colour through `Style.disabled` | yes, `:57` |
| empty text and icon | no intent, no Tab stop | yes, `:56`, `:59`, `:61` |
| long text | elides | when the host bounds the width; natural width stays the full text (CL-4 fixed in the component, source-reviewed, load-checked; Field and TextField still pending, see deferred) |

### Routes, the real ones

- Pointer: StateLayer TapHandler with `gesturePolicy: ReleaseWithinBounds` (`ControlLabel.qml:138`, `StateLayer.qml:170-183`). `onClicked` forces `MouseFocusReason` and activates (`ControlLabel.qml:140-143`). A press dragged off the target cancels.
- Keyboard: Tab and Backtab through `focusPolicy` (`:61`). Enter, Return and Space hold on press and activate on release while focused and available (`:74-93`). Auto-repeat is ignored (`:78`, `:87`). Focus loss, disable, `clickable: false` or empty text cancels a held press (`:69-72`, `:48-54`).
- Wheel: no wheel handler, so the label does not consume the wheel. Not verified at runtime.
- Assistive tech: Button role when clickable with content (`:65`), name `accessibleName` (`:66`), press action (`:67`). Passive labels report StaticText.
- Escape: not handled here. The host owns dismissal.

### Sizes, empty, long content, failure, cancellation

- md: text 12 (`Tokens.qml:36`), glyph 16 (`:43`), hit target 24 (`:45`), gap 4 (`:21`).
- `sizeScale`: text through `textNear(12 s)`, glyph through `iconNear(16 s)`, gap through `rhythm(4 s)` (`:98`, `:105`, `:115`). The hit target is `iconLg * sizeScale`, unsnapped (`:132-133`), see P-4.
- Icon only, no text: the caption hides, the glyph remains, the accessible name is empty (CL-5).
- Neither icon nor text: `visible` false, no focus (`:59`, `:61`).
- Long text: nothing bounds the width, so the row's implicit width grows with the text (CL-4).
- Failure: none on the label itself. Failed state belongs to Field (`Field.qml:44`).
- Cancellation: a held key is cancelled as above. A pointer press is cancelled by `ReleaseWithinBounds`.

### Visual roles and palette pairs

- Enabled text: `textMuted` (`:57`). Disabled: `Style.disabled(textMuted)` (`:57`).
- Required mark: `danger` (`:122`), disabled through `Style.disabled(danger)`. The `*` glyph is the non-colour channel (`:117-125`).
- Contrast of `textMuted` against the band or surface: not computed. The band is derived from the wallpaper at runtime, so the ratio needs a captured frame (ui-audit, not run).
- Focus ring: `Style.accent` by default (`StateLayer.qml:79`, `:156`). Two `spaceTight` outside the body, concentric by construction (`:147-156`).

### Motion and reduced motion (review-animations)

- No animation of its own. Inherited through StateLayer: hover scale to `Motion.hoverScale` 1.08 (`Tokens.qml:61`, `StateLayer.qml:113`, `:126-131`) over `Motion.micro` 130 ms, OutCubic (`Tokens.qml:47`, `Motion.qml:120`). Focus ring fades in over 130 ms (`StateLayer.qml:159-161`).
- Press: `pressScale` stays 1 (`StateLayer.qml:59`), so a press produces no motion (CL-1).
- Reduced motion: `Motion.press` falls to 40 ms and `Motion.micro` to 60 ms (`Motion.qml:24`, `:26`). `hoverScale` is not gated (`Motion.qml:46`), so the hover movement still plays (CL-3).
- Standards: 1 justified by state indication. 2 keyboard ring fade on Tab (SC-1). 3 ease-out for a move, which is correct. 4 durations under 300 ms; animate's table was not loaded, so not checked against it. 5 press scale missing (CL-1). 6 retargets through `Behavior`. 7 only scale and opacity animate. 8 fails on hover movement (CL-3). 9 no press motion to be asymmetric. 10 no local curve.
- Verdict for this item: Block. Reduced motion is not handled for the hover movement, and the focus ring fade awaits the owner's ruling (SC-1).

### Pointer geometry

- Input shape: when clickable, a rectangle centred on the footprint whose width and height are `max(footprint, 24 px at md)` (`ControlLabel.qml:128-134`). As a caption: no input, because the TapHandler is disabled and hover is not interactive (`StateLayer.qml:81-82`, `:170-172`).
- Painted size: a 16 x 16 glyph (icon only), or a 12 px text line (text footprint width not measured).
- Icon only at md: input 24 x 24, painted 16 x 16, so 4 px of overflow on each side.
- Model, all assumptions and not a human average: the pointer starts at the centre of a 380 px field (`Tokens.qml:86`) and moves in a straight line to the trailing glyph's centre, 360 px from the left edge (the slot sits 12 px from the right edge, half a 16 px glyph in from there). D = 360 - 190 = 170 px. Width W is the input width along the approach axis. Origin assumption: the pointer enters from the field's centre, not a corner. Weight assumption: equal for both approach directions.
  - W = 24 px (input): ID = log2(1 + 170/24) = 3.01 bits. Landing tolerance plus or minus 12 px on the approach axis.
  - W = 16 px (painted only): ID = log2(1 + 170/16) = 3.54 bits. Tolerance plus or minus 8 px.
  - The input shape removes 0.53 bits of difficulty at this distance.
- Neighbouring interference: TextField reserves the slot footprint plus a gap of `rhythm(8 s)` (`TextField.qml:176-180`) and an inset of `rhythm(12 s)` (`:175`). The 4 px overflow falls inside the gap at md, and at any scale the overflow (4 s) stays inside the gap (8 s), so no text sits under the hit target.
- Popup corridor and timing: not applicable. The label is not a popup and has no hover delay or keep-open logic.

### Findings

Source-backed defects:

- CL-1 (major, shared): a press shows nothing. The hit target has no press response (`ControlLabel.qml:132-143`, `StateLayer.qml:59`, `:113`), so the press changes nothing until the click fires on release. Fix: set `pressScale: Motion.pressScale` on the StateLayer at `ControlLabel.qml:132-143`. That also animates keyboard presses, because `manualPressOverride` drives `pressed` (`StateLayer.qml:83`, `ControlLabel.qml:136`), which breaks review-animations standard 2. So the full fix makes StateLayer's `response` (`:113`) follow the pointer press only, keeping `pressed` for colour. This needs StateLayer, hence shared.
- CL-2 (minor, fixed: source-reviewed, load-checked): hover does not change colour. AGENTS requires hover to grow and change colour. The StateLayer has no `hoverTint` (`ControlLabel.qml:132-143`), and the tint paints only with it (`StateLayer.qml:118-119`). Fix: `hoverTint: root.clickable` on the StateLayer at `ControlLabel.qml:132-143`.
- CL-3 (minor, source-conflict): reduced motion keeps the hover movement. `Motion.hoverScale` is not gated (`Motion.qml:46`), while the Motion header says reduced motion shortens durations rather than removing animation (`Motion.qml:20-21`). review-animations standard 8 says drop movement, keep colour and opacity. Fix, pending the owner's ruling: `hoverScale: Style.reducedMotion ? 1 : Tokens.motionHoverScale` at `Motion.qml:46`. Shared.
- CL-4 (major, fixed in the label: source-reviewed, load-checked; Field must give the label its column width and TextField must bound its leading slot, neither done): a long caption grows the control instead of eliding. `ControlLabel.qml:62-63` takes the implicit size from the row, and nothing bounds the Prose, so `ElideRight` (`Prose.qml:118`) never engages. AGENTS requires long content to scroll or elide, never to grow the control. A person sees a long Field caption run past the field's right edge (`Field.qml:52-56` gives the label no width), and a long leading label in a TextField shrink the text area (`TextField.qml:177-178` reads the slot's implicit width). Fix: bound the Prose by the width the host gives the label (`root.width` minus icon, gap and required mark), so elision engages. Field then gives the label its column width. Not shared.
- CL-5 (minor, fixed: source-reviewed, load-checked; route to a11y-audit): an icon-only clickable label has an empty accessible name. `accessibleName` defaults to `text` (`ControlLabel.qml:26`), and the Button role is set regardless (`:65-66`). A screen reader announces a nameless button. A caller that passes a name is fine. Fix: warn once when `clickable && text === "" && accessibleName === ""`, failing loud. Not shared.
- CL-6 (minor, fixed: source-reviewed, load-checked; route to a11y-audit): the required mark is not in the accessible name or description. The `*` is visual only (`ControlLabel.qml:118-125`), and the name is `accessibleName` (`:66`). Field puts "Required" on its own accessible description (`Field.qml:44`), not on the label. Fix: set `Accessible.description` to "Required" on the label when `required`. Not shared.

Source conflicts (owner ruling):

- SC-1: review-animations standard 2 says keyboard-initiated actions get no animation, while `StateLayer.qml:159-161` fades the focus ring in on every keyboard focus, and AGENTS requires the keyboard ring. Decide whether focus traversal counts as an action.
- SC-2 is CL-3.

Hypotheses (unmeasured):

- H-1 (resolved by the CL-4 change: the icon Loader is `visible: active`, source-reviewed, load-checked): a text-only label started about 4 px in. `Row` spacing applies before the zero-width inactive icon `Loader` (`ControlLabel.qml:98-108`), and this would show in Field captions and the unit's `icon: none` state. Check: dump `Prose.x` with `icon` empty.
- H-2: a disabled action still reports the Button role, because `:65` ignores `enabled`. Check: the disabled state in the accessibility tree (a11y-audit).
- H-3: below `sizeScale` 1 the hit target shrinks under the 24 px WCAG 2.5.8 floor, because `:132-133` scales `iconLg` by `sizeScale`. Whether a host reaches `sizeScale` below 1 depends on the Field and Slider size presets.
- H-4: `required` as a property name (`:24`) is a QML contextual keyword. The parse was not checked, because qmllint was not run.

Redesign proposals (taste, not defects):

- P-1: delete the hover growth on a label-sized target. 1.08 on a 16 px glyph is about 1 px of movement, and the colour change carries the state (review-animations standard 10: delete when unsure).
- P-2: a text-only caption could take its hit target from the text line instead of a fixed 24 px, so the hit target matches what it names.
- P-3: the `*` as a glyph in `danger` is fine. No change proposed.
- P-4: the hit target `iconLg * sizeScale` (`:132-133`) could go through `Style.iconNear` or `Style.rhythm` to match the rest of the scale. Polish.

Not examined: runtime (no capture, no Workbench, no tests run); the text footprint width; the contrast of `textMuted` against the band; glyph rendering (offscreen does not rasterise `SvgIcon`); touch targets (pointer only); Slider label clicks (BACKLOG R2 and R3: the Slider unit does not answer them).

Routes: a11y-audit owns CL-5, CL-6 and H-2. ui-audit owns the contrast ratio. ux-audit owns H-3.
