# Field

The one label element above a control with its hint or error on one shared line; invalid input is a fact, failed is this host verdict with copy.
states: hint and failed; `failed` is true while `error` has non-blank text and error wins over hint; the label, hint and error collapse when empty; the error is a wrapping message with a `circle-alert` glyph on its first line, the hint is plain text on the same left edge as the label and the control.
actions: none of its own; the wrapped control keeps its actions and routes.
pointer: a click on the label puts the caret in the control, as a label does (a pointer focus, so the keyboard ring stays off); content and message rows claim nothing beyond their children.
keyboard: none on the wrapper itself; the wrapped control keeps its tab stop and keys.
screen reader: the control is named by the label and described by the active hint or error plus "Required" (`accessibleName` and `accessibleDescription`, bound to the control unless the host already set its own); the label node itself is ignored, so the name is spoken once. Qt has no invalid-entry state, so the error copy in the description is how a failure is announced.
size: `sizeScale` follows the control the field frames (a host states it only to override) and scales the label, message, glyph and gaps; one gap of `rhythm(space2 * s)` (8) binds label, content and message, past the focus ring's reach (4.8 px at 1.25); width follows the content.
tokens: space1, space2, rhythm, textNear, textXs, iconNear, iconXs, danger, textMuted, ControlLabel and Prose; no local colours or measurements.
motion: none; state changes settle in the wrapped control.
not designed: input, validation logic or layout beyond one labelled control; use TextField, the control itself or the host for those.

## UIX audit

Evidence: geometry from the live item tree and the accessibility tree from AT-SPI, both in a headless slot at scale 1.25; owner-accepted: none.

### Purpose and consequence

It names one control from outside and puts its requirement, hint and failure copy beside it. A person reads the name and the fix before typing, and sees why the control failed. Field owns no input, action or pointer target; the wrapped control does.

### Controls and states

- Unit controls (`workbench/units/Field.qml`): control text/switch, validation ok/failed/long, hint shown/none, required yes/no, size sm/md/lg. The frame follows the control's own scale.
- Implemented: hint; failed (the error replaces the hint on the same line); required mark; collapse of the label, hint and error when empty.
- Story key: `field` only, variant `error`.
- Not reached by the unit: a long label, and a required field with an empty label (a caller error that logs at load).

### Routes

- Pointer: none on the wrapper. ControlLabel is a caption (`clickable` false, ControlLabel.qml:18), and its StateLayer has no tap handler. The message Prose has no handler.
- Keyboard and focus: none on the wrapper. The wrapped control keeps its tab stop (`activeFocusOnTab` in Switch.qml) and its keys.
- Wheel: none.
- Accessibility: Field exposes `accessibleName` (the label) and `accessibleDescription` (the error, or the hint, plus "Required") at Field.qml:43-44. It has no role of its own, and the host must bind those properties. A host that binds only the name leaves the description unspoken (F5). Criteria are a11y-audit's and were not run.

### Sizes, empty, long, failure, cancellation

- Size: `sizeScale` reaches the label, the message, the glyph and both gaps.
- Empty: the label row is invisible when the label is empty (ControlLabel.qml:59). The message row is hidden when there is neither an error nor a hint (Field.qml:69).
- Long: the message wraps and never elides (a 380 px field: 1 line short, 3 lines long); the label is single-line and elides (F3).
- Failure: `failed` is `error.trim().length > 0`, so whitespace is not a failure. The host owns the verdict and the copy. A host derives `error` from its own operation state.
- Cancellation: nothing in Field. The host clears `error`.

### Visual roles and palette pairs

- Roles: label `textMuted` (ControlLabel), required mark `danger`, hint `textMuted` and error `danger` as `body` at the field's text step, the glyph `circle-alert` at `iconXs`.
- No literal colour, size, radius or spacing in Field.qml. Spacing is `Style.space2` and `Style.space1`.
- Structure: label, control and message all start at x=0 on one left axis; the error text starts after its glyph.
- Contrast is token arithmetic: WCAG 2.2 relative luminance of the deep-night hex values in `qml/QsmShell/Style/Tokens.qml`. Nothing was sampled from a render.

| pair | band #271e30 | surface #3b3145 | overlay #4c4357 |
| --- | --- | --- | --- |
| danger #f5aeb7 | 8.84 | 6.79 | 5.17 |
| textMuted #c5bad1 | 8.61 | 6.61 | 5.04 |

Metadata is normal text, so 4.5 applies (1.4.3). Every pair passes. Field paints no background, so the host surface decides which column applies. The light theme was not examined.

### Motion and reduced motion

None in Field.qml. The failure swap is instantaneous. There is no reduced-motion form to define, and review-animations was not run.

### Pointer geometry

Field adds no pointer target. Its only input is the wrapped control. Worked example for the unit's Switch at md, computed from Switch.qml (implicit size = knob x 2 + inset x 2 by knob + inset x 2) and the tokens (`sizes.Switch.md` 16, `spaceTight` 2, `iconSm` 16):

- Input shape: the Switch's bounds, 36 x 20 px. Painted track 36 x 20 (radius height / 2); painted knob 16 px. The focus and hover layer (40 x 24, Switch.qml StateLayer) is visual only, because it is hosted and the button owns the pointer.
- Origin assumption: the pointer starts at the label's centre, the label above the control. A 16 px label line is assumed, not read (`typeSm` was not read).
- Distance: D = 7 (half label) + 8 (`space2`) + 10 (half track) = 25 px, vertical.
- Width model: W = 20 px, the track height on the vertical approach. A horizontal approach would use 36 px, which this path does not take.
- Difficulty: ID = log2(1 + D/W) = log2(2.1) = 1.07 bits, the Shannon form of Fitts' law (Fitts, 1954). A model of this geometry under the stated origin, not a human average.
- Landing tolerance: ±10 px vertically from the track centre. The knob does not narrow the target.
- Neighbouring interference: the label and the message row are passive, so no other target falls inside the 24 px circle that WCAG 2.5.8 uses for its spacing exception. The 20 px height is below the 24 px floor and passes only through that exception. The Switch record decides this.
- Trajectory: no popup, so no trigger-to-panel corridor applies.

### Findings

Defects (source-backed):

- F3 (low): ControlLabel's Prose is single-line and elides (Prose.qml:114, :118, role `label`). A long label is cut on screen, while the full name stays in `accessibleName` (Field.qml:43). Fix belongs to ControlLabel, which Slider also uses.

Not examined: the light theme; long and empty label cases in the unit; a real screen reader (the AT-SPI tree was read, not an announcement). Caelestia's nearest sibling, StyledTextField.qml, also shares one slot between supporting text and error text (`effectiveSupportingText`), which agrees with Field's shared-line rule. Its message wrapping was not checked.
