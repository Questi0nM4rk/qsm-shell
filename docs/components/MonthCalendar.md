# MonthCalendar

`MonthCalendar` moves the host-owned month while keeping a stable today marker.
Buttons, arrow keys, and vertical wheel input share `shiftMonth(delta)`;
horizontal wheel input remains available to an enclosing scroller.
The seven-column grid has a fixed natural size and uses only `Style` tokens.
Today is the sole accent; weekday and out-of-month dates recede quietly.

Not designed: date selection, ranges, locale-specific week starts, or a
dense multi-month picker.

## UIX audit

Evidence: source-reviewed only. No capture, preview, live geometry dump or runtime run was made, so
every number below is read from the source or is a labelled assumption. Read: `MonthCalendar.qml`,
`IconButton.qml`, `Prose.qml`, `StateLayer.qml`, `tokens/deep-night.json` (the only token file; no
light or high-contrast values exist), `workbench/units/MonthCalendar.qml`, the story key
`MonthCalendar / August 2026`. Theme: deep-night only.
Owner acceptance: none.

### Purpose and consequence

The type finishes one task: a person looks at a month, pages to another, and sees where today falls
in it. The consequence of a wrong month or a lost today marker is a wrong date read off the screen.

### Controls, states and routes

- Expected public controls: `shown` (the month, host-owned), `today` (the reference date,
  host-owned), the intent `monthShifted(delta)`, and the action `shiftMonth(delta)`.
- Implemented: `shown` and `today` are plain properties (`MonthCalendar.qml:12-13`). `shiftMonth`
  writes `shown` itself (`:17`), then emits `monthShifted` (`:18`). See defect `qss-bcn`.
- States: any month; today in the month, outside it, or absent. No selection, no range, no
  disabled limits (ranges are a non-goal in the record above).
- Pointer: the previous and next `IconButton` (`:35`, `:37`) call `shiftMonth` on click.
- Keyboard: `Keys.onLeftPressed` and `Keys.onRightPressed` on the root (`:24-25`). The root sets
  `focus: true` (`:23`) and has no `focusPolicy` or `activeFocusOnTab`, so it is not a Tab stop. The
  chevrons are `StrongFocus` and answer Return, Enter and Space (`IconButton.qml:22`, `:68-70`).
- Wheel: one `MouseArea` covers the whole component with `acceptedButtons: Qt.NoButton`
  (`:79-88`). Vertical wheel shifts one month per event; horizontal wheel is handed back.
- Focus mark: the chevrons carry the `StateLayer` ring (`StateLayer.qml:147-162`). The root and the
  day grid carry none.
- Accessible names: the chevrons are named "Previous month" and "Next month". The day
  grid has no `Accessible.*` property anywhere in the file.

### Sizes, empty and long content, failure, cancellation

- Sizes: `size` names a preset of the `MonthCalendar` table, the day cell's side: md 32, sm 24. Natural
  height is constant: header 32 px (`IconButton` 16 + 2 x 8), spacing 4, weekday row (`Prose` 12 px,
  14 high), row spacing 4, six rows of cells with spacing 4, which is 266 px at md and 218 px at sm.
  The 42-cell model fixes it. Passes by source.
- Natural width is constant: seven cells and six 4 px gaps, 248 px at md (the rail rollout's content
  width) and 192 px at sm. A host may widen it and the cells stretch.
- Long content: only the month title varies. Its role `title` elides (`Prose.qml:118`) when the host
  constrains the width; no empty state exists because the grid always shows 42 cells.
- Failure: no failure path is defined for an invalid `shown` or `today`. Not examined further.
- Cancellation: none. A wheel gesture cannot be cancelled; `angleDelta.y` accumulates one month per 120 units.

### Visual roles and palette pairs

Computed from the deep-night token values against `band`, the unit AGENTS names:

| Pair | Where | Ratio |
| --- | --- | --- |
| `text` on `band` (title, in-month days) | `:36`, `:68` | 13.71 |
| `textMuted` on `band` (weekday labels, chevrons) | `:47`, `:35` | 8.61 |
| `textMuted` at opacity 0.4 on `band` (out-of-month days) | `:68-69` | 2.55 (`Style.recede(Style.textMuted)` keeps `Style.contrastText` on the band by construction) |
| `textOnPrimary` on `accent` (today digit) | `:68` | 8.87 |
| `accent` on `band` (today disc) | `:61` | 8.87 |

Roles used: `title` (14 px, bold), `reading` (day digits, 12 px, technical face), `accent`
on the today disc only. The disc is 24 px, `Style.space5` (the whole cell at sm), centred in its cell. The hover disc of a chevron is `Style.tone` through `IconButton`; not computed here.

### Motion

None in this file: no `Behavior`, no transition, and a month change is instant. Chevron feedback is
`StateLayer`'s, which uses `Motion.micro`, `Motion.press` and `Motion.pressScale`. The
review-animations skill was not run; nothing here is judged for motion.

### Pointer geometry

Assumptions are labelled. No human average is claimed.

- Input shape: each chevron's hit area is its `IconButton` box, 32 x 32 (`IconButton.qml:24-25`,
  padding 8 set at `MonthCalendar.qml:35` and `:37`; `StateLayer` fills it, `StateLayer.qml:57`).
  Painted: a 16 px glyph and a 32 px hover disc (`StateLayer.qml:61`, `focusRadius` is height / 2).
  The square's corners, about 220 px2 of its 1024 px2, lie outside the painted disc and still hit.
- Minimum size: 32 px is above the 24 px pointer floor (WCAG 2.5.8, as cited in ux-audit) and below
  the 44 px touch floor. The touch floor matters only if touch is a supported input.
- Origin (assumption): the pointer starts at the title's centre. Not a measured trajectory.
- Width model (assumption): `W_nat = 80 + T`, where 80 = 2 x 32 + 2 x 8 and T is the rendered title
  width. T is estimated, not measured: about 76 px for "May 2026" and about 130 px for "September
  2026", from typical sans advance widths. The spread is the claim; its size is an estimate.
- Distance D from the title's centre to each chevron's centre = W_nat / 2 - 16: 62 px (May) to 89 px
  (September).
- Width W = 32 px, the nominal width along the approach axis. No effective-width correction, because
  no human sample exists.
- Difficulty ID = log2(1 + D / W): 1.56 bits (May), 1.92 bits (September).
- Landing tolerance: plus or minus 16 px horizontally and vertically about each chevron centre.
- Neighbouring interference: the chevrons are W_nat - 16 apart (140 px in May, 194 px in
  September). No third target lies within 32 px. The day cells and the title have no pointer
  handler, so nothing else is a target.
- Wheel: the whole component is the wheel target (`:79-80`), so no geometry applies.
- Popup corridor: none in this component; the host's corridor is the host's and was not examined.

### Findings

Defects (source-reviewed, each cited by file and line):

- `qss-bcn` (confirmed, major): `MonthCalendar.qml:17` assigns the host-owned `shown`. A host that
  binds the month loses that binding on the first click, which is what `units/MonthCalendar.qml:28`
  does. A host that never binds `shown` relies on the component's own
  state. The fix changes that: `shiftMonth` reports intent only, and the host sets `shown` from
  `monthShifted(delta)`. The change is outside this type's own files, so this finding is marked
  shared.
- `mc-today-stale` (minor, conditional): `:13` evaluates `new Date()` once, when the component is
  created, and nothing refreshes it. If the instance stays loaded past midnight, the marker stays on
  the previous day. Whether an instance lives that long depends on the host. Fix: one `Timer` set
  to the milliseconds to the next local midnight that updates `today`.

Redesign proposals (taste, not defects):

- The month title uses role `title` (14 px, bold), the weight of a card row. Role `heading` would
  state the component's job, but it widens the header.
- The day grid has no roles. Whether to expose it as a grid is for a11y-audit.
- Up and Down keys do nothing. That is correct for a month picker; nothing to add.
- The today accent disc is the only accent, which fits the accent rule (accent marks what is
  current). Keep.

Source conflicts: none.

Hypotheses (not measured, not in the table):

- H1: arrow keys may reach the root only while a chevron holds focus, because the root is not a Tab
  stop (`:23`). a11y-audit runs the keyboard path.
- H2: the vertical wheel over the calendar may stop a scroll container around it, since `MouseArea`
  accepts it (`:79-88`). Whether the host sits in a scroller was not read.
- H3: digits centred by bounding box (`:63`) may sit a pixel off optically. Not measured.
- H4: a 32 px target is below the 44 px touch floor. Matters only if touch is supported.

Not examined:

- Runtime: no capture, no preview, no live geometry. All geometry is source-derived or assumed.
- Light and high-contrast themes: the token set holds deep-night only.
- Text scaling: the pixel sizes are fixed and were not tested.
- Keyboard, focus and screen-reader behaviour at run time: a11y-audit's.
- Motion: none in this file; review-animations not run.
- The title width T: estimated, not measured.
- `tests/units/tst_MonthCalendar.qml`: present, not read or run (no tests requested).
- Caelestia: `~/Clonned/caelestia/repo/components/controls/` holds 21 files and none is a calendar,
  so there is no sibling to compare.
- A host at run time, including whether it scrolls (H2, H3).
- Invalid `shown` or `today` values: no failure path in the source; not examined.
