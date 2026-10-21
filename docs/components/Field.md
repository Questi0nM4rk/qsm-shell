# Field

The one label element above a control with its hint or error on one shared line; invalid input is a fact, failed is this host verdict with copy.
states: hint and failed; `failed` is true while `error` has non-blank text and error wins over hint; the label, hint and error collapse when empty.
actions: none of its own; the wrapped control keeps its actions and routes.
pointer: none on the wrapper itself; content and message rows claim nothing beyond their children.
keyboard: none on the wrapper itself; the wrapped control keeps its tab stop and keys.
screen reader: the host binds the wrapped control to `accessibleName` and `accessibleDescription`; these expose the label and active hint/error plus required status, without replacing a caller's accessibility bindings.
size: `sizeScale` from the owning surface scales the label, message, glyph and gaps with the control; tight vertical spacing binds label, content and message; width follows the content.
tokens: space1, spaceTight, rhythm, textNear, iconNear, textXs, iconXs, danger, textMuted, ControlLabel and Prose; no local colours or measurements.
motion: none; state changes settle in the wrapped control.
not designed: input, validation logic or layout beyond one labelled control; use TextField, the control itself or the host for those.

## UIX audit

Evidence: source-reviewed only. No capture, preview, live item tree or Workbench session was taken, so every geometry number here is computed from source and token values. Runtime-exercised: none. Owner-accepted: none.

### Purpose and consequence

It names one control from outside and puts its requirement, hint and failure copy beside it. A person reads the name and the fix before typing, and sees why the control failed. Field owns no input, action or pointer target; the wrapped control does.

### Controls and states

- Unit controls (`workbench/units/Field.qml`): validation ok/failed, hint shown/none, required yes/no, size sm/md/lg. Size reaches the wrapped Switch, and the label follows through `sizeScale`.
- Implemented: hint; failed (the error replaces the hint on the same line); required mark; collapse of the label, hint and error when empty.
- Story key: `field` only, variant `error`.
- Not reached by the unit: a long label, a long error, and a required field with an empty label (a caller error, see F4).

### Routes

- Pointer: none on the wrapper. ControlLabel is a caption (`clickable` false, ControlLabel.qml:18), and its StateLayer has no tap handler. The message Prose has no handler.
- Keyboard and focus: none on the wrapper. The wrapped control keeps its tab stop (`activeFocusOnTab` in Switch.qml) and its keys.
- Wheel: none.
- Accessibility: Field exposes `accessibleName` (the label) and `accessibleDescription` (the error, or the hint, plus "Required") at Field.qml:43-44. It has no role of its own, and the host must bind those properties. A host that binds only the name leaves the description unspoken (F5). Criteria are a11y-audit's and were not run.

### Sizes, empty, long, failure, cancellation

- Size: `sizeScale` reaches the label, the message, the glyph and both gaps (F2, fixed).
- Empty: the label row is invisible when the label is empty (ControlLabel.qml:59). The message row is hidden when there is neither an error nor a hint (Field.qml:69).
- Long: the label and the message are single-line and elide (F1, F7).
- Failure: `failed` is `error.trim().length > 0`, so whitespace is not a failure (F6, fixed). The host owns the verdict and the copy. A host derives `error` from its own operation state.
- Cancellation: nothing in Field. The host clears `error`.

### Visual roles and palette pairs

- Roles: label `textMuted` (ControlLabel), required mark `danger`, hint `textMuted` at metadata size, error `danger` with the `circle-alert` glyph at `iconXs`.
- No literal colour, size, radius or spacing in Field.qml. Spacing is `Style.space1` and `Style.spaceTight`.
- Structure: label, control and message all start at x=0 on one left axis (Field.qml:49 ColumnLayout).
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
- Distance: D = 8 (half label) + 4 (`space1`, Field.qml:49) + 10 (half track) = 22 px, vertical.
- Width model: W = 20 px, the track height on the vertical approach. A horizontal approach would use 36 px, which this path does not take.
- Difficulty: ID = log2(1 + D/W) = log2(2.1) = 1.07 bits, the Shannon form of Fitts' law (Fitts, 1954). A model of this geometry under the stated origin, not a human average.
- Landing tolerance: ±10 px vertically from the track centre. The knob does not narrow the target.
- Neighbouring interference: the label and the message row are passive, so no other target falls inside the 24 px circle that WCAG 2.5.8 uses for its spacing exception. The 20 px height is below the 24 px floor and passes only through that exception. The Switch record decides this.
- Trajectory: no popup, so no trigger-to-panel corridor applies.

### Findings

Defects (source-backed):

- F1 (high): Field.qml:78-83 sets the failure copy in `role: "metadata"`. Prose.qml:114 makes non-body roles `NoWrap`, and Prose.qml:118 makes them `ElideRight`. A message wider than the field (380 px in the unit, `Style.controlWidth`) is cut with an ellipsis, and the fix clause that the comment at Field.qml:32 asks for is the part that disappears. Fix in Field.qml: override the message's `wrapMode` to `Text.WordWrap` and `elide` to `Text.ElideNone`, then decide its leading (P1).
- F2 (medium): FIXED (message `textNear`, glyph `iconNear`, gaps `rhythm`, all times `sizeScale`; source-reviewed, load-checked, not owner-accepted). Field.qml:40 accepts `sizeScale`, but only ControlLabel receives it (Field.qml:55). The message (Field.qml:78-83, fixed `textXs`), the icon (Field.qml:75, `iconXs`) and the gaps (Field.qml:49 `space1`, Field.qml:70 `spaceTight`) do not scale. At the Switch's lg, `_s` = 24 / 16 = 1.5 (Switch.qml `_s`; `sizes.Switch` in tokens). The label grows by 1.5 and the message stays put. AGENTS.md: everything connected to the component scales with it. Fix in Field.qml: `Style.textNear(Style.textXs * root.sizeScale)` for the message, `Style.iconNear(Style.iconXs * root.sizeScale)` for the icon, `Style.rhythm` for the gaps.
- F3 (low): FIXED (the glyph keeps its slot at opacity 0 while a hint shows; source-reviewed, load-checked, not owner-accepted). the message RowLayout (Field.qml:67-70) gets the icon as a visible child only when failed (Field.qml:73). When the error appears the message moves right by iconXs + spaceTight = 12 + 2 = 14 px. The comment at Field.qml:64-66 says the layout must not jump, and it only keeps the vertical position. Fix in Field.qml: keep the icon's slot while a hint shows (opacity 0 when not failed, not `visible: false`).
- F4 (low): FIXED (a `required` field without a label logs an error at load, and "Required" is announced only with a label; source-reviewed, load-checked, not owner-accepted). Field.qml:36 and :44 add "Required" to the description even when the label is empty. ControlLabel.qml:56 and :59 hide the whole label row when its text is empty, and the asterisk (ControlLabel.qml:118-125) goes with it. A person sees no label and no mark, while a screen reader hears "Required". Fix: either Field refuses `required` without a label, or the mark shows without one. Choose one.
- F5 (medium, shared): a host that binds only the field's `Accessible.name` leaves the hint and the error visible but out of the field's description (Field.qml:44). Fix in the host: bind `Accessible.description` to the Field's `accessibleDescription`.
- F6 (low): FIXED (`failed` and the hint row use a trimmed message; source-reviewed, load-checked, not owner-accepted). Field.qml:42 treats whitespace as an error. The result is a lone danger icon with no text (Field.qml:72-83). Fix: `error.trim().length > 0`, and the same trim for `hint` (Field.qml:69).
- F7 (low): ControlLabel's Prose is single-line and elides (Prose.qml:114, :118, role `label`). A long label is cut on screen, while the full name stays in `accessibleName` (Field.qml:43). Fix belongs to ControlLabel, which Slider also uses.

Proposals (taste, owner decides):

- P1: the failure copy is the smallest, lightest text on the surface, yet it carries the instruction the person must follow. Consider role `supporting` (same colour, body size) or a weight step. A wrapped message also needs its own leading, because Prose sets line height 1 for every non-body role.
- P2: the gap from the control to the message is the same 4 px as the gap from the label to the control (Field.qml:49). The message therefore reads as part of the control's group. Consider a smaller gap below the control than above it, then check it in the live window.

Source conflicts: none between owners. Internal: the comment at Field.qml:32 asks for a full fix message, and F1 means the implementation cuts it.

Hypotheses (unmeasured):

- H1: the icon and the message may sit at different vertical centres in the RowLayout (Field.qml:67-84 sets no `Layout.alignment`), while AGENTS.md records that RowLayout baseline-aligns text. Needs a live item-tree read.
- H2: an error that appears is not announced, because the message carries no role or live region (Field.qml:78-83). Criteria are a11y-audit's.

Needs a live window (not run here): with a long server error in a password row, check that the message is cut (F1) and that it shifts (F3). Pass criterion for F1: the full message reads without an ellipsis.

Not examined: rendered pixels and the live item tree (no capture); the light theme; long and empty label cases in the unit; accessibility criteria (a11y-audit). Caelestia's nearest sibling, StyledTextField.qml, also shares one slot between supporting text and error text (`effectiveSupportingText`), which agrees with Field's shared-line rule. Its message wrapping was not checked.
