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

Evidence: source-reviewed; D1-D3 fixes load-checked by one offscreen capture of story `prose`. No live geometry, no owner acceptance.
Read: `qml/QsmShell/Components/Prose.qml`, `workbench/units/Prose.qml`, `tokens/deep-night.json`,
`qml/QsmShell/Style/Style.qml`, `AGENTS.md` (component laws, surface ladder), and the desktop
callers found by grep in `/home/qs_m4rk/Projects/qsm-desktop/shell` (modules/bar, modules/panel,
modules/launcher, modules/session, modules/clipboard, modules/cheatsheet, components/PopoutRow.qml).
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
  See D2 and H1.
- Failure: an unknown role string renders as `label` with no warning (lines 79 and 93). See D3.
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
| text `#f0ecf5` | 13.71:1 | 9.38:1 | 7.18:1 |
| textMuted `#c5bad1` | 8.61:1 | 5.89:1 | 4.51:1 |

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

Source-backed defects:

- **D1** (fixed; source-reviewed, load-checked, not owner-accepted) `workbench/units/Prose.qml:13` and `:34`. The unit declares `property bool technical: false`
  and binds `technical: root.technical` on the specimen, so the specimen's technical default
  (`role === "reading"`, Prose.qml:61) is overridden by a constant false. A person who picks the
  `reading` option sees the sans face, and the `technical` observable reports false. The harness
  therefore shows a state the component does not produce on its own.
  Fix: remove the explicit binding and make the technical control's options include an "auto"
  option that assigns nothing (or assigns the role default), so the unit shows the component's own
  default. Shared: false.
  Severity: medium.
- **D2** (fixed; source-reviewed, load-checked, not owner-accepted. Prose now always sets `ElideRight`, which Qt applies to a wrapping body only under `maximumLineCount` or an explicit height. The host line in `BarPopouts.qml` is now redundant and is left to the desktop.) `qml/QsmShell/Components/Prose.qml:118` (with `:114`). For `body`, `elide` is `ElideNone`
  whatever `maximumLineCount` is. A body capped by a caller ends at the cap with no ellipsis.
  The one caller that caps it, `qsm-desktop/shell/modules/bar/BarPopouts.qml:229-241`, re-sets
  `elide: Text.ElideRight` and says so in its comment, so the component's policy is patched by the
  host. A person sees the two-line app detail end mid-word unless that host line exists.
  Fix: make elide follow the line limit in Prose, `ElideRight` when `maximumLineCount` is set and
  `ElideNone` when it is not (check Qt's default for the unset value before writing the test). Then
  the host line can go. Shared: false.
  Severity: low.
- **D3** (fixed; source-reviewed, load-checked, not owner-accepted. Warns once per instance and role value; the fallback render stays.) `qml/QsmShell/Components/Prose.qml:79` and `:93`. An unknown role string falls to the
  `default` branches and renders at `textSm` in Medium weight, with no warning. A misspelt role such
  as `"headline"` reads as a plain label, and nothing says why. This is the silent fallback the
  implementation rule forbids; the library's own precedent is Style.size, which warns once
  (Style.qml:264, `console.warn`).
  Fix: warn once with the role name on the default branches, following the Style.size pattern.
  Shared: false.
  Severity: low.

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
  source conflict between the comment and the code, inside one file. The measured ratio (5.89:1 on
  surface, 4.51:1 on overlay) does not decide it; the owner does. Shared: false.
- Metadata and section on overlay: 4.51:1 at 10 px passes 4.5:1 by 0.01. A proposal, not a
  defect: keep those roles on surface or give them text colour on overlay. Shared: false.
- `Style.trackingWide` is `1.4` in `tokens/deep-night.json` (line 145, "tracking": "wide") with no
  unit, and Prose.qml:106 applies it as pixels, so section tracking is 0.14 em at 10 px. Whether
  1.4 is meant as px or em is not stated anywhere. Fix: state the unit in the token and in Style.qml.
  Shared: true (tokens/*).
- Surface ladder, side finding outside Prose: AGENTS.md says each step is 1.30:1 on the one below.
  Measured from the token values, band to surface is 1.46:1 and surface to overlay is 1.31:1
  (source-conflict between AGENTS.md and tokens/deep-night.json). The owner decides which is the
  ladder. Shared: true (tokens/*, Style/*).
- Unit ladder height, `workbench/units/Prose.qml:21`: `Style.controlWidth * 2` is an unlabelled
  ratio (760 px at controlWidth 380). The ladder's content is far smaller by estimate, which is not
  measured here. Fix: derive the height from the content (`implicitHeight` of the column). Shared:
  false.
- Callers: `qsm-desktop/shell/modules/bar/ClockEntry.qml:116` sets `technical: true` on `role:
  "reading"`, which the default already gives. Harmless; a desktop tidy-up, outside this library.

Hypotheses (observed in source, not measured):

- H1: in Qt, a Text with wrapping or `NoWrap` and no width reports its unwrapped line width as
  implicit width, so a body or title Prose placed in a Row without `fillWidth` or `width` grows its
  parent. Not run; the desktop callers all set width, which hides it.
- H2: `font.capitalization` (line 107) changes the rendered case only, so the accessible text of
  `section` probably stays mixed case. Confirm under a11y-audit, not here.
- H3: Prose uses Qt's default render type; caelestia sets `NativeRendering`. Fractional glyph
  positions could soften 10 px text. Not measured; test only when owner asks for a visual check.

Not examined: runtime rendering of any role; live geometry; pixel sampling; the story windows
(not started, per AGENTS.md); themes other than deep-night (only that set exists in `tokens/`);
empty-text height; keyboard, focus and screen-reader criteria (a11y-audit owns them; Prose is not
interactive); the desktop's rendered output.

Owner acceptance: none. The type has not been reviewed by the owner in the live window.
