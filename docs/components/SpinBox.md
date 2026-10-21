# SpinBox

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture | A compact auxiliary control for a practiced user setting one bounded numeric value; not a calculator or free-form expression editor. | Spinbuttons are for discrete bounded values (WAI-ARIA APG); the shell is a learned sovereign tool. | native spinbutton | UX audit: purpose and affordance are immediate |
| task | Show the host's value and let pointer, keyboard, wheel, accessibility actions, or direct text entry request a bounded change. | Qt DoubleSpinBox and the APG converge on one field with decrease/increase actions. | `T.DoubleSpinBox` | UX audit: every route changes the same value |
| interaction | Decrease is left, increase right; click steps once, hold repeats, wheel and Up/Down step, Home/End move the caret while editable and reach the bounds when read-only (`toMinimum()`/`toMaximum()` stay available either way), Return or focus loss accepts valid edited text. | Qt template behavior plus APG keyboard contract; focus remains on the field. | `decrease()`, `increase()`, `toMinimum()`, `toMaximum()` | UX audit: pointer, hold, wheel, keys and actions |
| ia | One focusable body contains both indicators and a centred editable reading; labels and error copy remain outside in `Field`. | A spinbutton is one value, not three tab stops; one label element names a control from outside. | content item + two indicators | Tree audit: one control and no internal label |
| hierarchy | One quiet `surface` body; hover/focus lift the fixed body, indicator glyphs grow and press inward, and only a failed host verdict adds a border. | The surface ladder and five-state law reserve borders for semantic facts. | `Surface`, `StateLayer` | UI audit: rest/hover/press/focus/failed are distinct |
| token | `size` resolves to `fieldHeight` (Control family: xs 24 / sm 32 / md 40 / lg 48); width is the constant `spinBoxWidth` scaled with the instance; text, glyphs and insets snap to their own scales. | One scale per instance; long formatted values scroll inside instead of resizing the control. | `sizes.Control`, `geometry.spinBoxWidth`, `textNear`, `glyphAlone`, `rhythm` | UI audit: sm/md/lg and long text |
| responsive | RTL mirrors the indicators; locale, decimals, validator, `textFromValue` and `valueFromText` remain Qt's public formatting contract. | Numeric order and formatting are locale facts, not painted literals. | Qt locale and mirroring | UX audit: RTL and formatted-value scene |
| state | Rest, hover, press, focus, disabled, editable/non-editable, bound-disabled indicators, wrapping, and host-owned failed are designed; disabled roles blend individually. | Every supported state needs an answer; unavailable is not opacity on a composite. | `Style.tone`, `Style.disabled`, danger focus | UI audit: every property-only state |
| accessibility | The native spinbox exposes value/min/max/value text; `accessibleName` supplies its external name, focus stays on the field, and indicators do not add tab stops. | Native semantics first; APG requires one named spinbutton with current value and bounds. | Qt accessibility bridge | Tree audit and keyboard-only pass |
| events | `valueModified()` reports accepted text and interactive pointer, wheel and keyboard changes; `stepUp()`, `stepDown()`, `toMinimum()` and `toMaximum()` explicitly report programmatic actions once. Native `increase()`/`decrease()` methods alone do not promise a `valueModified()` report. | Qt separates numeric setters from user-value acceptance; callers needing an intent report use the component actions. | `actions` list | Unit test: host feedback, native input and component actions |
| expected | A host answering component actions or native input receives the final bounded value; a later host write remains visible. Direct calls to inherited native setters change the value but do not synthesize an intent report. | Feedback is driven by the explicit value-modified contract, not every numeric setter. | host-owned `value`, native input and component actions | Real QML host-binding regression with fractional values, bounds and repeated host writes |

Not designed: arbitrary-precision numbers, expressions, units with incompatible parsing, an internal label, async validation. Radix and shadcn expose no dedicated number-input primitive; Material 3 supplies text-field guidance rather than a spinbutton. Caelestia custom JavaScript stepping was rejected in favor of Qt native stepping; this component's explicit actions add the report expected by a feedback host.

## UIX audit

Evidence: source-reviewed only. Read: `qml/QsmShell/Components/SpinBox.qml`, `Surface.qml`, `StateLayer.qml`, `Style.qml`, `Tokens.qml`, `Motion.qml`, `tokens/deep-night.json`, `workbench/units/SpinBox.qml`, the story titled "SpinBox / Decimal" in `workbench/stories.json`, and caelestia `components/controls/StyledSpinBox.qml`. Not run: no capture, no Workbench session, no live geometry, no tree dump, no test run. Contrast values are arithmetic on token hex values, not sampled pixels. Owner acceptance: none.

### Purpose and consequence

The task is the one in the table above. Unchanged.

### Controls and states

| Expected | Implemented | Where |
| --- | --- | --- |
| `value`, `from`, `to`, `stepSize`, `decimals`, `wrap`, `editable`, `failed`, `enabled` | Yes; `editable` defaults to `true` and the consumer may override it | `SpinBox.qml:40`, `:134`, `:117`; unit `:10-30` |
| `size` (sm, md, lg) | Yes, through `Style.size` | `SpinBox.qml:14-15`; `Tokens.qml`, `deep-night.json` Control row: xs 24, sm 32, md 40, lg 48 |
| `accessibleName` | Yes, but the default is empty, so an unnamed field is possible | `SpinBox.qml:18`, `:44` |
| `actions`: increase, decrease, minimum, maximum | Yes, each enabled from the bound it would cross | `SpinBox.qml:92-97` |
| States: rest, hover, press, focus, disabled, editable and non-editable, wrap, failed, bound-disabled indicators | Yes, as listed in the state row above | `SpinBox.qml:113-120`, `:199-240`, `:242-252` |

### Routes (real ones)

| Route | Real implementation | Note |
| --- | --- | --- |
| Pointer, indicator | Qt native press and hold on `up`/`down`; glyph `StateLayer` `SpinBox.qml:219-227` | Hold rate is Qt's; not in this source |
| Pointer, editor | `TapHandler` `:149-151`, `selectByMouse` `:138` | Click places the caret; drag selects |
| Wheel | `wheelEnabled: root.enabled` `:42` | Over the whole body, not only the field |
| Keyboard, Up/Down/Return/focus-out | Qt native | Not verified in source |
| Keyboard, Home/End | `_handleBoundKey`, bound on root and editor | Bounds only when read-only; an editable field leaves the key to the caret (D1, fixed) |
| Programmatic | `stepUp()`, `stepDown()`, `toMinimum()`, `toMaximum()` `:56-57`, `:89-90` | `valueModified()` reported once per call (`:69`, `:85`) |
| Focus | `focusPolicy: StrongFocus` `:43`; keyboard-only ring via `_pointerFocus` latch `:34-36`, `:148-151` | See H1 |
| Accessibility | `Accessible.name` `:44`; indicators are not focusable; spinbutton value and bounds are Qt's | Criteria belong to a11y-audit |
| Cursor | `HoverHandler` `:254-266`: arrow on indicators, I-beam on the field | Matches the cursor law |

### Sizes, content, failure, cancellation

- Sizes: sm, md and lg resolve through `Style.size`. Measured in token arithmetic: sm text 12 and glyph 12, md text 14 and glyph 16, lg text 18 and glyph 20 (`textNear` and `iconNear` snap the scaled values).
- Width: the preferred width is the constant `naturalWidth`, scaled and snapped to the 4 px rhythm (`:46-47`). It is not content-derived, which satisfies the law.
- Long content: the editor is a clipped centre viewport, 60 px at md (`:125-141`); it scrolls rather than resizes. The number of characters that fit at md is H6.
- Empty: `value` is always numeric, so the field cannot be empty in the component.
- Failure: a host-owned `failed` draws a 2 px `danger` border (`:117-119`) and a danger focus ring (`:251`). The copy belongs to `Field`.
- Invalid typed text: `acceptableInput` is exposed (`:38`), and nothing draws it. See H3.
- Cancellation: no Escape handling in the component. Releasing a press ends the step.

### Visual roles and palette pairs

Token arithmetic, source-reviewed. The body is the `surface` role on the `band` silhouette.

| Pair | Ratio | Threshold cited |
| --- | --- | --- |
| text `#f0ecf5` on surface `#3b3145` | 10.53 | 4.5 body text (1.4.3) |
| textMuted `#c5bad1` glyph on surface | 6.61 | 3 non-text (1.4.11) |
| accent `#d9b4ea` caret and ring against band `#271e30` | 8.87 | 3 non-text, if the ring's outside neighbour is band; the parent is not known here |
| textOnPrimary `#271e30` on accent (selection) | 8.87 | 4.5 body text |
| danger `#f5aeb7` failed border against band | 8.84 | 3 non-text |
| danger border against surface | 6.79 | 3 non-text |
| surface against band (the body's own step) | 1.30 | the ladder's step |

The hover lift (`Style.tone`, `Style.qml:126`) and the disabled blend (`opacityDisabled`) are not computed; see Not examined.

### Motion and reduced motion

- Hover and press use `Motion.micro` (130 ms) and `Motion.press` (80 ms), which become 60 and 40 ms under reduced motion (`Motion.qml:24`, `:26`). This is a shortened duration, which is the allowed form.
- The caret blink is gated on `Style.reducedMotion` (`:186-187`): under reduced motion the caret is solid.
- The caret jumps to its new position; no animation.

### Pointer geometry

Assumptions, stated as such: origin is the editor centre at body coordinates (70, 20); the travel is an equal-weight step up or down from rest; the pointer does not arrive from outside the body, so the approach distance is not modelled. Nothing here is a human average.

Width model: W is the indicator's full width along the travel axis, 40 px at md (indicator Item `:205`, `StateLayer` fills it `:220`). The target is square at 40 px tall, so the same W holds on both axes. Shannon form: ID = log2(1 + D / W).

| Route | D (centre to centre) | W | ID (bits) |
| --- | --- | --- | --- |
| editor centre to up indicator | 50 | 40 | 1.17 |
| editor centre to down indicator | 50 | 40 | 1.17 |
| up indicator to down indicator | 100 | 40 | 1.81 |

Input shape against painted size (md):

- Body: painted 140 × 40, radius 12. The root `HoverHandler` covers 140 × 40 but only sets the cursor.
- Down indicator: hit 40 × 40 at x 0–40. Glyph painted 20 × 20 (`glyphAlone`), 23 px on hover (`hoverScale` 1.15, `:225`), 17.2 px on press (`pressScale` 0.86, `:226`).
- Editor: hit 60 × 40 at x 40–100, a click target that does not step.
- Up indicator: hit 40 × 40 at x 100–140.
- Focus ring: 2 px at 4 px outside the body, radius 16.

Landing tolerance: ±20 px along x and y from each indicator centre. The up indicator's outer edge is the body edge, so a press that overshoots is still on the target, but the inner edge borders the editor directly.

Neighbouring interference: the gap between the indicators and the editor is 0 px. A landing one pixel inside the editor places the caret and does not change the value. Mis-hits therefore cost a caret move, not a value change.

Scale: sm gives a 32 px indicator, 112 px body and 48 px viewport. lg gives a 48 px indicator, 168 px body and 72 px viewport. Scale factor s = fieldHeight / 40.

Popup corridor: not applicable (the field is not a popup).

### Findings

#### Source-backed defects

| id | file:line | what a person sees | fix | shared | severity |
| --- | --- | --- | --- | --- | --- |
| D1 | `SpinBox.qml:42` | When the field sits in a scrolling list and the pointer is over it, a wheel step changes the value and the list does not scroll. This applies when the field is hosted in a scroller. | Gate the wheel on focus, `wheelEnabled: root.enabled && root.focused`, or keep it and record the owner's ruling. The trade-off is discoverability of the wheel. | false | minor |

#### Redesign proposals (taste, not defects)

- P1. Indicators are glyphs in a fused body. Caelestia uses separate round steppers that morph their inner radius on press, with a 2 px label offset (`StyledSpinBox.qml`). The fused body suits the Quiet Luminous direction, so keep it; a body-level press response may still be worth judging live.
- P2. The failed state is a 2 px danger border, and the only other cue is host copy. Whether 2 px is enough is a live judgement, and whether colour alone carries it is a11y-audit's.
- P3. `accessibleName` defaults to empty (`:18`), so an unnamed field is announced without a name. Whether the library warns or requires a name is a decision for a11y-audit and the owner.
- P4. Indicator hover changes glyph size only. The whole body lifts on hover (`:116`), so the indicator under the pointer is shown only by its growth. Judge live.

#### Source conflicts

- S1. The interaction row of this record says "Home/End reach bounds". Native text editing uses Home and End to move the caret (`SpinBox.qml:102-108` implements the record's rule while read-only). Owner ruling needed.
- S2. The unit's control reads "read-only" (`workbench/units/SpinBox.qml:53-56`), while the component keeps stepping, wheel and Home/End active when `editable` is false (`SpinBox.qml:40`, `:42`, `:99-108`). Which meaning is intended is an owner ruling.

#### Hypotheses (not measured)

- H1. If a press on an indicator does not move focus to the field, the `_pointerFocus` latch set by the root's `pressed` (`SpinBox.qml:36`) stays set. Then the first keyboard Tab into the field shows no focus ring until focus leaves. Check: press an indicator without focusing the field, then Tab in, and read the ring.
- H2. `_toBound` calls `increase()` or `decrease()` once per step (`:76-84`). On a wide range with a small step, Home or End could block the UI thread for a long time. Measure the loop at the largest supported range before calling it a defect.
- H3. The component exposes `acceptableInput` (`:38`) and draws nothing for invalid text. What Qt does with invalid text on focus-out is not in this source.
- H4. `_step` calls `valueModified()` after Qt's `increase()` (`:59-71`). If Qt also emits `valueModified` inside `increase()`, a programmatic step reports twice. The record's events row says Qt does not; that is unverified here.
- H5. Hold repeat rate is Qt's; this source sets no repeat value. The rate is unknown.
- H6. If the monospace advance is about 0.6 em, the 60 px md viewport fits about 7 characters at 14 px. The advance is not measured.

#### Not examined

- Live window, captures, tree dump, keyboard in the Qt accessibility tree, screen reader, 200% text scale, RTL mirroring (`:233`, `:239`), locale decimals.
- Hover lift colour from `Style.tone` (`Style.qml:126`) and the disabled blend `opacityDisabled`: neither value was read or computed.
- `tests/units/tst_SpinBox.qml`: listed by the story, not read and not run, per instruction.
- Placement in a real scroller (D1) and any real instance.
- Whether `Field` renders the failed copy, which belongs to that component.
