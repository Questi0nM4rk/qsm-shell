# Divider

One thin line; decorative separation and nothing else.
states: none; it is never hovered, pressed, focused, selected or disabled.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; a decorative rule with no accessible name.
size: implicit height is its own thickness; the drawn line insets symmetrically so anchored and fixed-width consumers behave alike; the item may claim a gap while the ink stays one pixel.
tokens: textMuted and the strength fraction; `lineColor` and `thickness` remain overrides for foreign grounds such as a band.
motion: none.
not designed: labelled separators, interactive structure or spacing; use ListRow header rows, Section or layout gaps for those.

## UIX audit

Evidence: source-reviewed only. No Workbench session, preview, capture or tree dump was run, so every
geometry value below is computed from source, not read from a running tree. Owner acceptance: none.

### Purpose and consequence

The rule separates two groups on one surface or band and carries nothing else. Without it, adjacent
groups read as one list. Too heavy, it reads as a bar; the rail's rule is the current case (see
proposals).

### Controls, states and routes

- Properties (Divider.qml:18-21): `inset` (0), `strength` (.35), `lineColor` (Style.textMuted),
  `thickness` (1). All four are implemented.
- Actions: none. The unit declares controls for the desktop cases and for strength, thickness, colour and
  inset (workbench/units/Divider.qml, `controls`).
- States: none, by design (docs line 4). Not a focus stop, takes no keys and no wheel: Divider.qml
  contains no MouseArea, Handler, Behavior or Animation (grep count 0).
- Pointer, wheel, focus: no route. A Rectangle with no handler does not accept pointer or wheel events
  (Qt Quick behaviour, not run here), so they reach whatever lies beneath it.
- Accessibility: no role and no name; decorative. Criteria are a11y-audit's; run it on any surface that
  contains a Divider.

### Sizes, empty, failure

- Height: implicitHeight = thickness (Divider.qml:23). Default 1 px; the rail uses 2 px
  (RailDivider.qml:15).
- Width: no implicitWidth. A Divider given no width, anchors or Layout width draws nothing and reports
  nothing (Divider.qml:30 becomes max(0, 0)). Every current caller sets one of these.
- Content: none. Failure: only the silent empty case above. Cancellation: not applicable.

Callers in source: ListRow.qml:212 and 218 (header rules, strength 0.5), ListRow.qml:222 (separator,
inset space3, strength 0.5); NotificationCard.qml:566 (bottom rule, inset 20, strength 0.25 from line
226); MenuRow.qml:27 (short centred rule, width 96, strength 0.25); RailDivider.qml:10 (band colour,
thickness 2, strength 0.8, inset 8) used at Rail.qml:86, 189, 213, 228, 328 and RailDeviceCell.qml:97,
105 (rotated 90 degrees).

### Visual roles and palette pairs

The line is `textMuted` (deep-night.json color.textMuted #c5bad1) at `strength` opacity over its ground.
Only the deep-night values were read. Effective colours are computed, not sampled: sRGB blend
`a x textMuted + (1 - a) x ground`, WCAG relative luminance.

| ground | strength | line colour | ratio of line to ground |
| --- | --- | --- | --- |
| band #271e30 | 0.25 | #4e4558 | 1.77 |
| band #271e30 | 0.35 (default) | #5e5568 | 2.26 |
| band #271e30 | 0.5 | #766c80 | 3.22 |
| band #271e30 | 0.8 (rail) | #a59bb1 | 6.02 |
| surface #42394c | 0.35 | #70667b | 2.02 |
| overlay #534a5e | 0.25 (menu) | #70667b | 1.54 |
| overlay #534a5e | 0.5 | #8c8298 | 2.30 |

The rule is decorative, so no 3:1 requirement applies (WCAG 1.4.11 covers non-text content that
carries meaning); this record does not claim one. The colour is a token; the default opacity is a
literal (defect 2).

Motion: none; no reduced-motion form to specify. review-animations has nothing to judge.

### Pointer geometry

- Input shape: none. No handler, so the item is not a target.
- Painted size: width = parent width minus 2 x inset; height = thickness (1 px default, 2 px rail).
- D, W, ID: not applicable; there is no target to aim at. Width model: none. Origin assumptions and
  label weights: none, because there is no pointer path. For scale only: a 1 px line taken as a target
  at D = 100 px gives ID = log2(1 + 100/1) = 6.66 bits, which is why the item must never be a target.
- Neighbour interference: none from the Divider. Target spacing belongs to the neighbouring rows
  (ListRow.qml) and is not measured here.
- Popup corridor and timing: not applicable.

### Findings

Fixed (source-reviewed, load-checked; not owner-accepted):

- Defect 3 (record named space3, which Divider.qml never reads): removed from line 10.
- Defect 4 (unit showed one default rule, no controls): the unit now carries a `case` control (default,
  list header, list separator, card bottom, menu short, rail, rail turned) that sets inset, strength,
  thickness, colour, width, claimed gap, rotation and ground together, plus single controls for
  strength, thickness, colour and inset. No new story key. The rail's rule colour is textMuted
  (Theme.railDivider), not the band colour the finding named.

Source-backed defects (numbering kept; 3 and 4 above are fixed):

1. ListRow separator lands on a half pixel. ListRow.qml:99 gives the separator height Style.space3 = 12
   (Tokens.qml:23). ListRow.qml:226 sets `y: (root._headingHeight - height) / 2`, which is (12 - 1) / 2
   = 5.5 at that height. The 1 px rule is painted across two pixel rows at about half intensity, so it
   looks softer than the header rules. The same arithmetic holds for any even `_headingHeight`. Proof:
   the row's tree `y`. Fix: round the offset in ListRow.qml, not in Divider. Severity: minor.
2. The default strength is a literal inside a component. Divider.qml:19 `property real strength: .35`,
   against AGENTS.md:332 (every measurement from Style). A consumer's backend cannot retheme the
   default line opacity. Fix: read the default from a Style token (Tokens.qml, Style.qml). Shared: yes
   (Style and tokens). Severity: minor.
3. The record names a token the component does not read. docs/components/Divider.md:10 says tokens
   are "textMuted, space3 and the strength fraction". Divider.qml reads only Style.textMuted (line 20).
   space3 appears only in the unit, as the caller's inset (workbench/units/Divider.qml:27). Fix: remove
   "space3" from line 10. Severity: minor.
4. The unit does not show the cases the desktop uses (BACKLOG R4, confirmed). workbench/units/Divider.qml:21-33
   shows one default-strength rule inset by space3 between two labels. It shows none of: the rail rule
   (RailDivider.qml:10-17), the header rule pair (ListRow.qml:212, 218), the separator (ListRow.qml:222),
   the bottom notification rule (NotificationCard.qml:566-573), the short menu rule (MenuRow.qml:27-32),
   or the rotated arm (RailDeviceCell.qml:97-110). With `controls: []` (line 35) the owner cannot switch
   strength, thickness, lineColor or inset. Fix: add those cases to this unit through its existing
   properties, without a new catalog key. Shared: no. Severity: medium.

Source conflicts:

- Record line 3 says "decorative separation and nothing else". AGENTS.md:259 says "a line inside is
  content (a track, a meter), never an edge", and AGENTS.md:288 says "layers are separated by a step,
  never by a line". The border cases AGENTS.md lists do not include a separator. Whether a separator
  between rows is content or a forbidden line is the owner's ruling.

Redesign proposals:

- Strength is one bare fraction with no name. Callers pick 0.25 (NotificationCard.qml:226, desktop
  Theme.qml:431), 0.5 (ListRow.qml:212, 218, 222) and 0.8 (desktop Theme.qml:426). A small named set in
  Style would let the owner judge one set. The values themselves are the owner's to choose.
- The rail rule is 6.02:1 against band; the library default is 2.26:1 (table above). It reads closer to
  a bar than a hairline. Judge it in the live window; this is taste, not a defect.
- Vertical orientation is deferred (docs/BACKLOG.md:93). RailDeviceCell.qml:97-110 fakes a vertical
  rule with rotation 90 on a 2 px horizontal one. An `orientation` property would remove the rotation
  and the risk in hypothesis 3.

Hypotheses (not measured, not in the table):

1. ListRow header rule (ListRow.qml:207-219): the header row is _headingHeight = Style.space4 +
   Style.space2 = 24 (ListRow.qml:100; Tokens.qml:24). If the RowLayout centres a 1 px child without
   rounding, y = 11.5, the same half-pixel as defect 1. A tree dump of the child's y settles it.
2. Divider.qml:26-27 centres the line with `anchors.verticalCenter`. Whenever height minus thickness is
   odd, the line lands on a half pixel. No current caller sets such a height (all rely on implicit
   height), so this is latent.
3. RailDeviceCell.qml:97-110: a 2 px line rotated 90 degrees about a centred item may sit on a half
   pixel when the cell centre falls on .5.
4. A Divider with no width draws nothing and reports nothing (Divider.qml:30). No caller in source does
   this.

Not examined:

- Light and high-contrast themes (only deep-night was read).
- Runtime geometry and captures (none run; no tree dump).
- Screen-reader exposure (a11y-audit).
- Comparison with other libraries: caelestia has no Divider or separator file (grep of
  ~/Clonned/caelestia/repo/components/controls for divider|separator found none); no other library was
  consulted in this pass.
- Motion: none exists, so nothing to review.
