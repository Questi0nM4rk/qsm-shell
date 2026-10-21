# Stat

A single value metric with trend semantics; it reads one number and which way it is moving.
states: none beyond its facts; trend up or down colours only when a `good` direction names the winner (default `none`, muted), and a worsening trend adds a warning glyph so the cue is not hue alone.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: value, label and unit are plain text roles; the trend glyph repeats the direction in shape and the warning glyph repeats an unwelcome one.
errors: an unknown `trend` or `good` logs a `console.error` naming the property and value; the trend glyph is then not drawn.
size: constant natural width `contentWidth` (default `Style.spinBoxWidth`); a long value or label elides inside it; value and unit share the technical face.
tokens: spaceTight, space1, spinBoxWidth, iconSm, iconXs, textMuted, success and warning; no local colours or measurements.
motion: none.
not designed: charts, selection or editing; use Sparkline, ListRow or the host for those.

## UIX audit

Evidence: source-reviewed only. No capture, no live item tree and no accessibility tree were taken,
and the owner has not accepted this type. Channels available: the source (`Stat.qml`, `Prose.qml`,
`SvgIcon.qml`, `workbench/units/Stat.qml`), the token values in `tokens/deep-night.json` and
`Tokens.qml`, and the story keys. Themes available: `deep-night` only. Contrast figures below are
computed from the token hex values on the ground each role sits on, not sampled from rendered pixels.

Purpose and consequence: one number, its unit, what it measures, and, when a `good` direction is
named, whether it is moving toward or away from that. The task it finishes is a glance at one
metric on a card or a bar. Consequence of a wrong reading: a person acts on a green arrow that means
the opposite.

Controls and valid states: `value`, `label`, `unit`, `icon`, `trend` (`""`, `up`, `down`, `flat`),
`good` (`up`, `down`, `none`), `emphasis` (`display`, `hero`), all declared in `Stat.qml` lines 19-28.
Implemented: all of them. The colour rule is `_trendColor`: muted when the trend is
empty or `flat` or `good` is `none`, `success` when trend equals good, `warning` otherwise. The unit
exposes trend, good, emphasis, label and the value (72, empty, long).

States: none. The component is not interactive and declares no state of its own. The five-state rule
does not apply.

Routes: pointer none, because no item in `Stat.qml` receives input, so the wheel passes through.
Keyboard none; it is not a tab stop and sets no `activeFocusOnTab`. Focus none. Accessibility:
`Stat.qml` sets no `Accessible.*` property. The trend direction and the good/bad colour exist only
as glyph and hue, and the name, role and tree shape are unread. Handed to a11y-audit.

Sizes: the component's rows take the constant `contentWidth`, and the unit centres it in a
`Style.controlWidth` square (380 at `tokens/deep-night.json`, unit lines 18-19). Tokens in use:
`textDisplay` 28 and `textHero` 44 for the value, `textXs` 10 for the label and metadata, `textSm`
12 for the unit, `iconSm` 16 for the trend glyph, `iconXs` 12 for the label glyph, `spaceTight` 2
and `space1` 4 for gaps (`Tokens.qml` lines 27, 35-41, 42-43; `Prose.qml` lines 65-81).

Empty and long content: an empty `value` renders an empty text with no source handling. The value and
label rows take the constant `contentWidth` (default `Style.spinBoxWidth`, for lack of a Stat width
token) and elide. Failure: an unknown `trend` or `good` string logs `console.error` and an unknown
trend draws no glyph. Cancellation: none.

Visual roles and palette pairs, computed from tokens:

| Ground | text 1:1 | textMuted | success | warning |
| --- | --- | --- | --- | --- |
| band `#271e30` | 13.71 | 8.61 | 9.41 | 9.13 |
| surface `#3b3145` | 10.53 | 6.61 | 7.23 | 7.01 |
| overlay `#4c4357` | 8.02 | 5.04 | 5.51 | 5.34 |

Every text pair clears 4.5 on all three grounds. The two trend
hues sit at 1.03:1 against each other, so their luminance gives no cue; a worsening directional trend adds an `alert-triangle` glyph in `warning`, so the state differs in shape as well as hue. Roles: the value
takes `display` or `hero`, the unit takes `reading` in muted colour (`Stat.qml` 48-54), the label
takes `metadata` in muted colour (78-81).

Motion and reduced motion: none. `Stat.qml` has no animation, transition or `Behavior`, and it
animates nothing through `Prose` or `SvgIcon`. The reduced-motion form is therefore not applicable.
Review-animations was not run.

Pointer geometry: not applicable. Stat is not a target, so it has no input shape to set against its
painted size, no distance, no width and no index of difficulty; ID is not defined without a target
to acquire. There is no trigger-to-panel corridor. Painted extents for reference: the value line box
is 28 px (44 px for hero) with `lineHeight` 1, the trend glyph 16 px, the label glyph 12 px, the label
line 10 px. Label origins and weights are not needed; the weights come from `Prose.qml` 82-95 (bold for
display, hero, reading, title and section; regular for body, supporting and metadata).

Hypotheses (unmeasured, to check on a capture or a tree):

- H1. The unit uses `Layout.alignment: Qt.AlignBottom` (line 49), which aligns box bottoms, not
  baselines. Their baselines sit apart by the difference in descent between the two sizes, minus the
  2 px `spaceTight` margin (line 50). The comment at lines 46-47 promises a shared baseline. Check
  by zooming the unit and the value on one capture, or from the tree's text geometry.
- H2. The trend glyph uses `AlignVCenter` (line 57) on a 28 px line box, so it centres on the box and
  not on the digits' visual centre. It may sit low against the figures. Check with a zoomed capture.
- H3. Whether the label at 10 px (`textXs`) is legible at a glance from the distance a bar is read.
  This is a judgement for the live window, not a source fact.

Not examined: capture and zoom (none run, per the brief); live geometry (none); the accessibility tree
and keyboard (a11y-audit owns these, and `Stat.qml` sets no `Accessible.*`); the light or high-contrast
theme (only `tokens/deep-night.json` was read); every surface a host might place the Stat on, which
only fixes its ground; motion (none exists). Sibling: caelestia's `components/controls/` has no stat or trend
component, so no comparison was possible.

Proposals (taste, not defects):

- Put the value and unit in one row with a shared baseline once H1 is measured; the current 2 px nudge
  is a token standing in for a metric difference.
- Consider whether the label should sit above the value as the reading's name, since a 10 px label at
  the foot of a 28 px reading is the weakest element on the card.
- Allow an icon-only metric: the label row, and its glyph, hide when `label` is empty (`Stat.qml` 69,
  73), so an icon with no name cannot be shown.
