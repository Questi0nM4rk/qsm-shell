# KeyValueRow

A compact label and reading pair for device and status lines; it shows the truth at full strength and is simply not a target.
states: none; it is never hovered, pressed, focused, selected or disabled, and dimming it would misreport a live reading as stale.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: label and value are plain text roles; the value keeps its reading role in the host's colour.
size: content-driven row with fixed spacing; the label fills and the value holds its natural width; the optional glyph is icon small.
tokens: space2, iconSm, text and textMuted; no local colours or measurements.
motion: none.
expected: setting, replacing or clearing `icon` after construction re-lays out the actual row before the next rendered frame; label and reading never overlap the glyph. No unit-side reconstruction or extra spacing compensates for it.
source: Qt RowLayout owns the optional glyph's participation and spacing; compare live geometry after render polish, not during the property-write stack. Caelestia has no corresponding passive label/value row. The native rendered-frame regression covers empty/populated/empty changes.
not designed: selection, action or editing; use ListRow, a slot action or the host for those.

## UIX audit

Evidence: source-reviewed only. Nothing here was rendered, captured or run. The contrast ratios are
computed from the hex values in `tokens/deep-night.json`, not sampled from pixels. Owner acceptance:
none.

Read: `qml/QsmShell/Components/KeyValueRow.qml`, `Prose.qml` (the roles it uses), `SvgIcon.qml`
(the glyph), `Style.qml` and `Tokens.qml` (values), `workbench/units/KeyValueRow.qml`, the story key
`key-value` in `workbench/stories.json`, and `tests/units/tst_KeyValueRow.qml` (read, not run).

### Purpose and consequence

A readout line. It finishes "what is the device reading right now" at a glance. The value stays at
full strength because a dimmed reading would look stale.

### Controls and states

- Public controls: `label`, `value`, `icon`, `valueColor` (KeyValueRow.qml:10-13). All four are
  implemented.
- Valid states: glyph present or absent; label and value short or long; `valueColor` default or
  host-set.
- Exposed by the unit: none. `controls: []` (workbench/units/KeyValueRow.qml:37). The catalog holds
  one key, `key-value`, with `variant: battery`, so the glyph is shown and the glyph-absent state
  appears only in the second row of the unit.

### Routes

- Pointer: none. No handler and no input item; wheel passes through.
- Keyboard: none. Not a tab stop.
- Focus: none, by design.
- Accessibility: the source sets no `Accessible.*` property in `KeyValueRow.qml` or `Prose.qml`.
  The accessibility tree was not read, so the record's "plain text roles" claim is not tested.

### Sizes, empty, long content, failure, cancellation

- Natural size: the root is a `RowLayout` with no `implicitWidth` or `implicitHeight`
  (KeyValueRow.qml:7-15), so its natural width is the sum of its children's widths. The unit sets
  `width: parent.width` (workbench/units/KeyValueRow.qml:25, 31) and so never measures the natural
  size.
- Glyph: `iconSm` = 16 (Tokens.qml:43). Gap: `space2` = 8 (Tokens.qml:22).
- Glyph absent: `visible: false` (KeyValueRow.qml:19).
- Long label: role `body` wraps (KeyValueRow.qml:27; Prose.qml:63, 114, 118). The row grows taller.
- Long value: role `reading` is `NoWrap` with `ElideRight` (Prose.qml:114, 118). Whether it elides
  in the row depends on the layout, see H1.
- Empty label or value: no handling; the text is empty.
- Failure: an unknown icon name loads no file and reports nothing (SvgIcon.qml:32-34). See P4.
- Cancellation: not applicable.

### Visual roles and palette pairs

- Label: Prose role `body`, muted. Text is `textMuted` (#c5bad1) on `band` (#271e30): 8.61:1,
  computed from token values. Passes 4.5:1 for body text (WCAG 1.4.3). The row paints no background,
  so the figure holds for the unit's ground only.
- Value: Prose role `reading`, `valueColor` = `text` (#f0ecf5) on `band`: 13.71:1, computed.
- Glyph: `textMuted` on `band`, 8.61:1. It sits beside its own label, so it is decorative; the
  1.4.11 non-text check applies only if it carries meaning the label does not.
- Type: label is `textSm` (12 px, Tokens.qml:36) at `lineBody` 1.55 and regular weight
  (Prose.qml:74, 91-92, 102). Value is `textSm` at line height 1, bold, technical face
  (Prose.qml:61, 77, 88, 102). The record's token list (space2, iconSm, text, textMuted) does not
  name these roles; it should.
- Motion: none. The glyph change is instant.

### Pointer geometry

- Input shape: none. There is no input item, so the row is not a target. D, W and ID are not defined
  and ID is not computed. No width model applies.
- Painted size, from the source: width is the host's width (380 in the unit, `controlWidth`,
  Tokens.qml:86). Height is the taller of the label and value line boxes. The label is one line of
  12 px x 1.55, about 18.6 px (assumption). The value's height at line height 1 is the font's own
  metric, not measured.
- Origins (assumptions): with the glyph hidden the label starts at `row.x`. The test asserts this
  (tests/units/tst_KeyValueRow.qml:34, 45), but the test was not run. With the glyph shown the label
  starts at 16 + 8 px from `row.x` (assumed from the sizes above).
- Corridor, trigger timing, landing tolerance and interference: not applicable. It is not a popup
  and has no trigger.

### Findings

Source conflicts (the owner decides):

- **SC1.** The record says the size is "content-driven row" (line 9). AGENTS.md says natural size is
  a constant and long content never grows the control. The record and AGENTS.md disagree. AGENTS.md
  is binding, so the record should change once the owner rules.

Proposals (taste, not defects):

- **P1.** The glyph is a name-selected bundled icon, a property. AGENTS.md says content goes in slots,
  not properties. Trade-off: a name keeps the readout a one-liner; a slot lets the host pass any
  glyph.
- **P2.** Label weight: the label role is medium, the body role regular. Choose one for a readout
  label; this is taste, so the owner decides.
- **P3.** `valueColor` lets a host colour a failed reading. Where colour alone says "failed", a11y-audit
  check 6 applies (WCAG 1.4.1). The host, not the component, must add text or an icon.
- **P4. Side finding, outside this file.** SvgIcon.qml:32-34 loads whatever `name` resolves to and
  reports nothing when the file is missing. A typo in `icon` shows an empty 16 px slot and an 8 px gap,
  so the label shifts right with nothing blank to explain it. The fail-loud fix belongs in SvgIcon,
  which owns the name set.

Hypotheses (observed in the source, not measured):

- **H1.** A long value may overflow the right edge instead of eliding. The reading has no
  `Layout.fillWidth` and no `maximumWidth` (KeyValueRow.qml:33-35), so it asks for its natural width.
  Whether the layout shrinks it to the `ElideRight` width depends on the minimum width the layout
  assigns to a `Text` item, which the source does not settle. Check: render the unit with a long value
  at `controlWidth`. Only when the owner asks.
- **H2.** The glyph and the text may sit at different vertical centres. The record and AGENTS.md
  both note that `RowLayout` aligns by baseline and that an icon has no baseline. The label's
  1.55 line box and the value's line height 1 make the centres differ further. Check: a live capture
  of glyph, label and value boxes.
- **H3.** A screen reader may announce label and value as two unrelated text nodes, because no
  `Accessible.*` property groups them. Check: read the accessibility tree of a running host, through
  a11y-audit.

Not examined:

- Live rendering, geometry and captures. The brief bars Workbench sessions and captures.
- tests/units/tst_KeyValueRow.qml was read but not run. AGENTS.md runs checks only when asked.
- Themes and variants other than deep-night. Only `tokens/deep-night.json` exists. Scale factor and
  high contrast were not reviewed.
- Reduced motion: no motion exists, so the question is not applicable.
- caelestia: only `components/controls/` was listed, and it holds no passive label/value row. Other
  caelestia directories were not searched.
