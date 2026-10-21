# Prose

The one type scale; ten roles from hero to section with muted and technical axes, and body is the only role that wraps.
states: none; roles, muted and technical are static facts, never interaction states.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: plain text always; single roles elide and body wraps; section renders uppercase with wide tracking as a label, not a shout.
size: pixel sizes from the text scale and weights from the weight scale; line height belongs to wrapping body only; technical roles use the technical face without kerning.
tokens: the text, weight, line and tracking scales plus text and textMuted; no local colours or measurements.
motion: none.
not designed: input, labelling controls or truncation policy beyond elision; use TextField, ControlLabel, Field or the host for those.

## UIX audit

Evidence: source-reviewed. No live geometry, no owner acceptance.
Read: `qml/QsmShell/Components/Prose.qml`, `workbench/units/Prose.qml`, `tokens/deep-night.json`,
`qml/QsmShell/Style/Style.qml` and `AGENTS.md` (component laws, surface ladder).
Caelestia sibling: `~/Clonned/caelestia/repo/components/StyledText.qml`.

### Purpose and consequence

Finishes one job: the text on a surface is set at the role the surface means, so importance is
one decision in one place. A wrong role reads to a person as the wrong importance (a heading that
looks like a label, a value that moves when its digits change).

### Controls and states

- Public API: `role` (ten names, default `"label"`, line 42), `muted` (default false, line 47),
  `technical` (default `role === "reading"`, line 61); inherited Text properties (`text`,
  `maximumLineCount`, `elide`, `width`, `color`) are used by callers.
- Implemented: all ten roles in the size and weight switches (lines 69-94); `muted` and the
  supporting, metadata and section colour rule (line 65); technical face (line 67).
- Valid states: none. No hover, press, focus or disabled exists, so none is owed.
- Unit controls: role (ten options), muted on/off, technical on/off (workbench/units/Prose.qml
  lines 58-77). Per-option availability is not applicable to a static type.

### Routes

- Pointer: none. No handler; the Text claims no events, so the wheel passes to the parent.
- Keyboard: none. Not focusable, no key handling.
- Focus: none. No focus ring owed.
- Programmatic: `text`, `role`, `muted`, `technical` only; no function, no signal.
- Screen reader: criteria are a11y-audit's and were not ruled on here. See Hypotheses.

### Sizes, content, failure, cancellation

Sizes are fixed by role from the Tokens type scale (`tokens/deep-night.json` "type": xs 10, sm 12,
md 14, xl 22, display 28, hero 44). Prose takes no size preset and does not scale with a host
control, which is deliberate: the caller picks the role.

- Empty text: not run.
- Long text: `body` wraps with no line limit (lines 114, 118); the other nine roles are
  `NoWrap` and elide right, so they end with an ellipsis only when the parent gives them a width.
  See H1.
- Failure: an unknown role string warns once per instance and role value and renders as `label`.
- Cancellation: none; the type has no work to cancel.

### Visual roles and palette pairs

| role | px | weight | colour | line height | case and tracking | face |
| --- | --- | --- | --- | --- | --- | --- |
| hero | 44 | DemiBold | text | 1 | mixed | sans |
| display | 28 | DemiBold | text | 1 | mixed | sans |
| heading | 22 | DemiBold | text | 1 | mixed | sans |
| title | 14 | DemiBold | text | 1 | mixed | sans |
| body | 12 | Regular | text | 1.55 | mixed, wraps | sans |
| label | 12 | Medium | text | 1 | mixed | sans |
| supporting | 12 | Regular | textMuted | 1 | mixed | sans |
| metadata | 10 | Regular | textMuted | 1 | mixed | sans |
| reading | 12 | DemiBold | text | 1 | mixed | monospace (technical) |
| section | 10 | DemiBold | textMuted | 1 | uppercase, 1.4 px tracking | sans |

Weights: `weightBold` is DemiBold (600), `weightMedium` Medium (500), `weightRegular` Normal (400)
(Style.qml lines 214-216).

Contrast of the pairs, computed from the token hex values (WCAG relative luminance, not sampled
pixels; Prose has no own background, so the ground is the caller's surface):

| text on | band | surface | overlay |
| --- | --- | --- | --- |
| text `#f0ecf5` | 13.71:1 | 10.53:1 | 8.02:1 |
| textMuted `#c5bad1` | 8.61:1 | 6.61:1 | 5.04:1 |

The 4.5:1 line (WCAG 1.4.3, body text) is met everywhere. textMuted on overlay passes by 0.01,
and it carries the 10 px metadata and section roles there.

### Motion

None. Prose has no animation and no `Behavior`, so the reduced-motion form is not applicable.
Caelestia's StyledText animates its text swap; Prose does not, by design.

### Pointer geometry

- Input shape: none. The item has no target, so there is no input shape apart from its painted
  text bounds.
- Painted size: the Text's implicit size, set by the text and the role; not a target.
- Label origins and weights as assumptions: not applicable; the caller places the text.
- D, W, ID = log2(1 + D/W): not applicable. There is no pointer task and no target width. Width
  model, if one were needed: none stated.
- Popup corridor and timing: not applicable.
- Neighbouring interference: none, because nothing reacts to the pointer.

### Caelestia comparison

`StyledText.qml` is a Text with `PlainText`, one font (`Tokens.font.body.small`), one colour
(`m3onSurface`), `NativeRendering`, and an opacity Behavior on `text` when `animate` is set. It has
no role axis and no technical axis. The ten roles and the face axis are this library's own
decision, justified in the Prose.qml header. Caelestia's `NativeRendering` is a difference to test,
not a defect (H3).

### Findings

Redesign proposals (taste; owner decides):

- Comment drift, no visible effect: Prose.qml:16 says "there are eight" roles and then lists ten.
  Fix the comment to ten. Shared: false.
- Comment drift, mechanism: Prose.qml:29-30 and :110-112 credit `font.kerning: !technical` with
  tabular numbers. The digits are tabular, if at all, because the technical family is the generic
  `monospace` (`tokens/deep-night.json` fontTechnicalFamily, Style.qml:192). Kerning off does not
  make a proportional face tabular, and no monospace font is bundled, so tabular digits depend on the
  host's default monospace. Fix the comment, and check the bundled-font question at runtime later.
  Shared: false.
- Colour of `supporting` (Prose.qml:65): the header (lines 26-27) says supporting is "meant to be
  READ, not skimmed past", but the rule paints it textMuted, the same colour as metadata. This is a
  source conflict between the comment and the code, inside one file. The measured ratio (6.61:1 on
  surface, 5.04:1 on overlay) does not decide it; the owner does. Shared: false.
- `Style.trackingWide` is `1.4` in `tokens/deep-night.json` (line 145, "tracking": "wide") with no
  unit, and Prose.qml:106 applies it as pixels, so section tracking is 0.14 em at 10 px. Whether
  1.4 is meant as px or em is not stated anywhere. Fix: state the unit in the token and in Style.qml.
  Shared: true (tokens/*).
- Unit ladder height, `workbench/units/Prose.qml:21`: `Style.controlWidth * 2` is an unlabelled
  ratio (760 px at controlWidth 380). The ladder's content is far smaller by estimate, which is not
  measured here. Fix: derive the height from the content (`implicitHeight` of the column). Shared:
  false.

Hypotheses (observed in source, not measured):

- H1: in Qt, a Text with wrapping or `NoWrap` and no width reports its unwrapped line width as
  implicit width, so a body or title Prose placed in a Row without `fillWidth` or `width` grows its
  parent. Not run; a caller that sets a width hides it.
- H2: `font.capitalization` (line 107) changes the rendered case only, so the accessible text of
  `section` probably stays mixed case. Confirm under a11y-audit, not here.
- H3: Prose uses Qt's default render type; caelestia sets `NativeRendering`. Fractional glyph
  positions could soften 10 px text. Not measured; test only when owner asks for a visual check.

Not examined: runtime rendering of any role; live geometry; pixel sampling; the story windows
(not started, per AGENTS.md); themes other than deep-night (only that set exists in `tokens/`);
empty-text height; keyboard, focus and screen-reader criteria (a11y-audit owns them; Prose is not
interactive).

Owner acceptance: none. The type has not been reviewed by the owner in the live window.
