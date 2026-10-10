# Field

The one label element above a control with its hint or error on one shared line; invalid input is a fact, failed is this host verdict with copy.
states: hint and failed; `failed` is true while `error` is set and error wins over hint; the label, hint and error collapse when empty.
actions: none of its own; the wrapped control keeps its actions and routes.
pointer: none on the wrapper itself; content and message rows claim nothing beyond their children.
keyboard: none on the wrapper itself; the wrapped control keeps its tab stop and keys.
screen reader: the host binds the wrapped control to `accessibleName` and `accessibleDescription`; these expose the label and active hint/error plus required status, without replacing a caller's accessibility bindings.
size: `sizeScale` from the owning surface scales the label with the control; tight vertical spacing binds label, content and message; width follows the content.
tokens: space1, spaceTight, iconXs, danger, textMuted, ControlLabel and Prose; no local colours or measurements.
motion: none; state changes settle in the wrapped control.
not designed: input, validation logic or layout beyond one labelled control; use TextField, the control itself or the host for those.
