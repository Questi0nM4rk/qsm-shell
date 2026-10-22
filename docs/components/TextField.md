# TextField

states: rest(surface on band, 1.30:1 from the deep-night ladder; no border) hover(the body grows one StateLayer growth step a side, 2 device pixels at 1.25, and lifts; the text, caret and slots stay put; read-only neither lifts nor grows; `growthCap` bounds it for a field with close neighbours) press(caret lands) focus(ring, keyboard focus only; `keyboardFocused` reports it, a click leaves the caret as the mark) disabled(surface, text, placeholder, caret and danger border each through Style.disabled) readOnly failed
actions: Accept Clear Reveal(password only) Select all
purposes: text search password number; one type, the purpose switches input semantics, leading glyph, trailing action and sample value together
size: `size` is a preset name (Control family) resolved by Style.size("TextField", name) into `fieldHeight` (escape hatch); s = fieldHeight / md; text textNear(textMd·s), slot content is the host's and the host scales it by `sizeScale` (the unit uses iconNear(iconMd·s)), insets rhythm(space3·s), slot gap rhythm(space2·s); a leading action owns the full-height strip from the field edge while its glyph keeps the inset; a trailing Control reserves only its glyph width (its padding is hit box and overflows, above the text); caret, radius and border constant; width naturalWidth = controlWidth, constant, text scrolls inside
tokens: space3 (box inset) space2 (slot gap) spaceTight (scroll-end inset) `Style.indicatorWidth` (caret width, danger border) radiusBody surface accent danger Style.disabled textSm|Md|Lg
motion: micro (surface, border); the caret never travels, it blinks at the platform cursorFlashTime/2 and stays solid while it moves, off under reducedMotion
events: accepted(only when acceptableInput) edited(text) escaped keyPressed(event, the one hook for every key a surface wants, Up/Down included) selectionClaimed
label: outside, through Field, which uses ControlLabel (the element Slider wears)
accessibility: the input is the one node a screen reader meets (role text, password text for a password; the frame is ignored); `Accessible.name` and `Accessible.description` set on the field, or by `Field`, are read by the input; the placeholder describes it when nothing else does; Qt withholds the name of a password input, so a password is named through its description; Qt has no invalid-entry state, so `failed` is spoken through the error copy `Field` puts in the description
not designed: multiline, autocomplete, floating label, filled/outlined variants
readOnly: no resting mark (owner ruling; the majority convention across M3, MUI, Fluent, Spectrum, Radix, Ant); it reports at full strength, takes no hover lift or growth and shows no caret, stays a tab stop and copyable
open: audit lines in docs/BACKLOG.md

## UIX audit

Evidence: source-reviewed only. No runtime, capture, live geometry or accessibility tree was used, and no owner acceptance exists. Contrast values are computed from the hex values in `tokens/deep-night.json` with WCAG relative luminance, not from rendered pixels. Only the deep-night theme is in `tokens/`, so no other theme is examined.

Sources read: `qml/QsmShell/Components/TextField.qml`, `workbench/units/TextField.qml`, `workbench/stories.json` (keys `text-input`, `search`, `password-input`, `number-input`), `Style.qml`, `Motion.qml`, `StateLayer.qml`, `Surface.qml`, `IconButton.qml`, `SvgIcon.qml`, `Prose.qml`, `Field.qml`. Sibling: caelestia `components/controls/StyledTextField.qml` and `TextFieldBase.qml`. Caelestia's field is outlined and Material-styled, so it informs the caret and placeholder, not the geometry.

### Purpose and consequence

The one text input a person uses to type or search a value, enter a password, or enter a number. If it fails, the person either loses typed input or gets no answer to Enter, so they cannot tell whether the value was taken.

### Expected controls and states

| Control or state | Implemented | Where |
| --- | --- | --- |
| purpose: text, search, password, number | Partly. The component switches `inputType` only: echo mode, validator, input-method hints. The leading glyph and trailing action live in the consumer (see SC2). | TextField.qml 91-100, 323-325; unit 31-45 |
| enabled, disabled | Yes. Disabled blends text, placeholder, caret, border through `Style.disabled`. | TextField.qml 210, 284, 304, 398 |
| failed | Yes. 2 px `danger` border (`Style.stroke(Style.indicatorWidth, root)`), and focus ring turns `danger`. The message belongs to `Field`. | TextField.qml 209, 454 |
| readOnly | Yes. No hover lift, no caret, still a tab stop. | TextField.qml 200, 400, 448 |
| size xs, sm, md, lg | Yes. 24, 32, 40, 48 px from the Control family. | tokens `sizes.Control`; TextField.qml 45 |
| empty, long | Yes. Empty shows placeholder; long text scrolls inside a constant 380 px width. | TextField.qml 167, 270-273, 278 |
| Clear | Action only, no visible control. Calls `input.clear()`, which is not an undoable act in this file. | TextField.qml 132, 140 |
| multiline, autocomplete, floating label, filled or outlined | Not designed (record line 11). | none |

### Routes

- **Pointer.** Press on the field focuses the input (TextField.qml 301-303, 461-469). Hover lifts and grows the surface (TextField.qml background). Cursor: I-beam over the body, pointing hand over the trailing slot (63, 480-489). No `WheelHandler` or wheel code exists in this file (grep: none), so the wheel passes to whatever contains the field (not measured).
- **Keyboard.** The input takes Tab (TextField.qml 298). The root has `focusPolicy: NoFocus` (186). Return and Enter claim selection and call `accept()` (359-362). Escape emits `escaped` and does not revert the text (365-367). Up and Down reach `keyPressed` and are not consumed (369-373).
- **Focus.** Keyboard only, through `StateLayer` (StateLayer.qml 147-170): a 2 px stroke with a 2 px gap outside the body, outer radius 16 px (12 px body + 4 px reach). A pointer press latches `_pointerFocus` and hides the ring until focus leaves (TextField.qml 119-120, 302). The caret is a 2 px accent bar (396-399).
- **Accessibility.** One AT-SPI node per field (measured): `text` with the name and description above; `password text` for a password; `READ_ONLY` while readOnly; no ENABLED or SENSITIVE while disabled. The unit names its fields (`Display name`, `Search settings`, `Network password`, `Brightness`) and its reveal action `Show password` / `Hide password`.

### Sizes and geometry

- Scale `s` = fieldHeight / 40: 0.8, 1.0, 1.3.
- Text (`textNear(14 · s)`): 12, 14, 18 px.
- Left and right inset (`rhythm(12 · s)`): 8, 12, 16 px.
- Slot gap (`rhythm(8 · s)`): 8, 8, 8 px.
- Height 32, 40, 48 px. Width 380 px, constant (`Style.controlWidth`).
- Radius 12 px (`radiusBody`), constant. Caret `Style.stroke(Style.indicatorWidth, root)` wide, a straight line.
- Slot glyphs: not sized by this component; the host takes `Style.glyphBeside(fieldHeight)` (16 at sm and md, 20 at lg). The unit does.

### Palette pairs (deep-night, computed)

| Pair | Ratio | Threshold | Note |
| --- | --- | --- | --- |
| text `#f0ecf5` on surface `#3b3145` | 10.53 | 4.5 | passes |
| placeholder `#c5bad1` on surface | 6.61 | 4.5 | passes |
| placeholder on lifted surface `#51495b` (hover and focus lift, `Style.lift` 0.4) | 4.63 | 4.5 | passes, narrowly |
| surface `#3b3145` on band `#271e30` (rest boundary) | 1.30 | 3 (1.4.11, a11y-audit decides) | no border at rest |
| lifted surface on band | 1.86 | none | hover reading |
| failed border `#f5aeb7` on band | 8.84 | 3 | passes |
| failed border on surface | 6.79 | 3 | passes |
| focus ring and caret `#d9b4ea` on band | 8.87 | 3 | passes |
| focus ring and caret on surface | 6.82 | 3 | passes |
| selection: text `#271e30` on accent `#d9b4ea` | 8.87 | 4.5 | passes |

Disabled colours blend 35 % toward band (`Style.disabled`) and are exempt from 1.4.3 as inactive components. Each palette pair is a token, so the pairs travel with the theme.

### Motion and reduced motion

- Surface colour and border: `Motion.micro`, 130 ms, reduced 60 ms (`Surface.qml` 42-44; TextField.qml 212-214).
- Caret blink: half of the platform `cursorFlashTime`, off under `Style.reducedMotion` (TextField.qml 393, 419-425).

### Pointer geometry

- **Input shape.** The root `T.Control` at 380 x 40 px (md) holds the hover and tap handlers (TextField.qml 182, 461, 480). The painted `Surface` fills the root. So the input shape equals the painted size for the body.
- **Slot actions.** A slot action sits inside the field, and its keyboard ring reaches two strokes (4.8 px at 1.25) past its box, so its box is at most the field height minus that on both sides: the unit uses `xs` (24) in md and sm, `sm` (32) in lg. At sm (32) no preset fits and the ring is 0.8 px past the field edge.
- **Origin.** The field is entered from its label, which `Field` places above it (`Field.qml` 52). The label's geometry is not in this file. The distances below are assumptions, not measurements and not a human average.
- **Width model.** Model A, vertical approach: W = 40 px. Model B, horizontal approach from a neighbour: W = 380 px. A press anywhere in the body lands, so the axis of approach sets W.
- **Difficulty.** ID = log2(1 + D / W), in bits:

| Target | W | D = 100 px | D = 300 px | D = 600 px |
| --- | --- | --- | --- | --- |
| field, model A (vertical) | 40 | 1.81 | 3.09 | 4.00 |
| field, model B (horizontal) | 380 | 0.34 | 0.84 | 1.37 |
| reveal action (unit, xs), horizontal | 24 | 2.37 | 3.76 | 4.70 |

- **Landing tolerance.** Centre landing within plus or minus 20 px vertically (field 40 px), plus or minus 12 px for the 24 px action.
- **Neighbouring interference.** The 24 px action sits 8 px inside the md field edge above and below (4 px at sm), so it never reaches a neighbour. Spacing between the field and its neighbours belongs to `Field` and the layout, not this file.
- **Popup corridor.** Not applicable: the field is not a hover-opened surface.

### Empty, long, failure, cancellation

- Empty: placeholder in `textMuted` (TextField.qml 284-288).
- Long: the input clips inside a constant 380 px width (TextField.qml 273, 309, 329). The caret keeps 2 px at the scroll edge.
- Failure: `failed` paints a 2 px danger border and a danger ring. `acceptableInput` is false for an intermediate number such as "1e" or "-" (validator is the built-in `DoubleValidator`, TextField.qml 91, 158-161). The component emits nothing and sets nothing. See D1.
- Cancellation: Escape emits `escaped` and leaves the text unchanged. The host decides whether to revert.

### Findings

Source-backed defects. Each cites a file and line, and says what a person sees.

- **D1, medium.** Pressing Return in a number field with intermediate text does nothing visible. `accept()` returns false silently (TextField.qml 126-131). The Return branch then sets `event.accepted = true` regardless (359-364). A person who types "1e" and presses Enter sees no border, no message and no change, because `accepted` is not emitted and `failed` is not set. Fix: emit a `rejected` signal from `accept()` when `!input.acceptableInput`, so the host can set `failed` and show its copy. Shared: no.

Redesign proposals (taste, not defects):

- P1. The password reveal should belong to the component, with one label and one checked state. Hosts use different labels for one act; the unit says "Show password" and "Hide password" (the GitHub, Radix and Fluent vocabulary).
- P3. Press has no body response. `Surface.pressed` is never bound (TextField.qml 188-215), so the lift of 0.8 in `Style.tone` never appears. The record says "press(caret lands)". Decide whether a text field's press is the caret alone.
- P4. Read-only keeps the I-beam (cursor, TextField.qml 480-489). A pointer sees an I-beam on a field it cannot edit. Consider an arrow when `readOnly`, keeping selection.
- P5. The purpose claim (line 5) needs either the composition moved into the component, or the claim narrowed.
- P6. The placeholder passes at 4.63 on the lifted surface. Re-check this pair if the lift changes.

Source conflicts (owner decides which wins):

- Hover growth: owner ("A nejde udělat prostě slight růst, tak že budeme všude počítat s tím, že věci musí být tak daleko, aby se jich hover nedotknul?"): the painted body grows by `StateLayer.growth` on every side, 1.6 px at md (a 380 x 40 field measures 383.2 x 43.2 under the pointer), and the content is a sibling at its own size, so nothing moves under the pointer.
- SC2. Record line 5 says the purpose switch changes "leading glyph, trailing action". The component changes `inputType`, validator and hints only (TextField.qml 91-100). The glyph and action come from the host, and each host builds them its own way.

Hypotheses (unmeasured):

- H2. The Clear action is not undoable in this file, but Qt's `TextInput` undo may survive `clear()`. Unverified.
- H3. The rest boundary (1.30:1) may fail the 3:1 of 1.4.11 if the field must be identified by its edge. This is a11y-audit's call.
- H4. Caret blink period depends on the platform's `cursorFlashTime`. Unmeasured.

Not examined:

- Runtime: no preview, capture, live geometry or accessibility tree was used, by instruction.
- Themes: only deep-night in `tokens/`. No light or high-contrast theme.
- Accessibility conformance: a11y-audit's table is not produced. The rest boundary, failed indicator (a colour and a 2 px border, with the message in `Field`) and the reveal name are named here as inputs to it.
- `tests/units/tst_TextField.qml` (512 lines): not read, not run.
- Wheel, drag selection, IME composition, and a host's own reveal controls were not measured.
- `Field.qml` label and error layout beyond the `ControlLabel` line.
