# ListRow

The row: one item a person operates repeatedly; the host owns selection, values, optional inline expansion and the action's consequence. Activating an item never means advancing selection.
states: rest, hover, press, focus, selected (the accent at `opacitySelected` as a fill behind the row and the name in the accent, spec 07; no side marker), disabled and report-only; header and separator are structural rows a cursor steps past; disabled dims an unavailable action while a report-only row stays full-strength and simply is not a target; recede dims unpicked rows only in lists you pick from.
actions: `activate()` guards selectable and emits `activated`; StateLayer click, pointer, keyboard and programmatic routes share it; keyboard navigation and focus belong to the owning list through `focused`.
pointer: StateLayer grows the leading box only; clickable trailing actions take their own grab, while passive readings remain part of the row target; hover reports `hoveredEntered` for the list cursor and wheel is not claimed.
keyboard: the owning list holds focus and routes arrows and Enter; the current row shows the focus ring on the body.
expected: the single-row unit owns focus and routes Enter through `activate()`; a physical trailing-action click reports only that action, body and passive-reading clicks activate the row, and long-content mode keeps both routes judgeable. Menu composition / Shell items hosts interaction between multiple rows and their editors; the row unit never implements a selector.
screen reader: selectable rows announce as buttons named by the primary label with supporting text as description; structural and report-only rows are static text.
size: sm, md and lg resolve through the control-height scale with the leading box at one fixed size per row; `headingHeight` is the host's absolute-height escape hatch, keeping body/input/editor origin aligned; readonly `expansionHeight` reports the actual revealed viewport for bounded surface sizing. Hosts never override total implicitHeight to set a heading. The asked width includes the inset the body gives away; long text elides and a supporting line that repeats the name hides.
tokens: control-height, icon and type scales, space scale, `opacitySelected` fill, opacity roles, surface ladder, accent, danger, Motion and StateLayer; no local colours or measurements.
motion: micro colour and opacity response; no position animation during a gesture; reduced motion shortens the durations.
expansion: host-owned `expanded` and named `expandedContent`; empty/structural rows reserve no editor space. Existing leading/trailing slots and heading size remain unchanged. The expansion is not a second row activation target; unavailable or collapsed content cannot handle input. Hosts choose the open/close consequence and focus destination.
alignment: readonly `contentInset` is the text column's leading edge. Expanded content starts there, directly beneath the heading, with Style.spaceTight top clearance and Style.space2 bottom clearance. No duplicate title or extra border; the same geometry hosts a slider or password form.
paint path: ListRow's host intent → clipped viewport height → full-size ColumnLayout slot at a fixed local origin below the heading → zero-height hidden viewport; content stays mounted. StateLayer/SelectionMark/body stay on the heading; no registry, shader or unload handoff is involved. Motion.fast/moveEasing reveal the viewport, not slider scaling; reduced motion removes that spatial reveal.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | transient shell action, adjust repeatedly without losing place | owner's keyboard contract | host-owned selection, controlled Slider | repeated activation and return focus |
| interaction | Enter/select opens; editor Enter/Escape returns to same item with applied value | no implicit advancement or hidden rollback | ListRow activation + expandedContent | keyboard/pointer/host flow |
| hierarchy/system | reading and disclosure cue on heading; horizontal editor directly below | local consequence, no popup or duplicate heading | Style row/type/space scales, Motion.fast | owner checks association and settled tail |
| responsive/state | fixed heading, elided text, full-width bounded slider; empty/disabled supported | component laws and blueprint | sm/md/lg, clip/input gate | owner review plus requested behavior check |

Not designed: multi-selection, nested disclosure, confirmation, asynchronous service results or a menu. No new tokens. APG Disclosure contributes explicit expansion, APG/Radix Slider its keys; Caelestia StyledSlider/MenuItem preserve input/intent separation. This is the existing row plus a content slot, not Disclosure's second heading.

## UIX audit

Evidence: source-reviewed only. No Workbench session, preview, capture or item-tree dump was run, so
no value here is measured from a live window, and no row is runtime-exercised or owner-accepted.
Live geometry channel: not reached. Every geometry number below is arithmetic on the token values in
`qml/QsmShell/Style/Tokens.qml`; every contrast ratio is computed from those token hex values with
WCAG 2.x relative luminance on the background named beside it.

Accessibility criteria (focus, keyboard, accessible names, colour-only meaning, reduced-motion
conformance) are a11y-audit's; run it for this surface.

### Purpose and consequence

The one line a person picks from in a list. It shows a name, an optional supporting line, a leading
visual and trailing content, and it reports `activated` when a press lands on it. The row never decides
what the activation does; the host does. A row with `interactive: false` only reports a reading.

### Expected controls and states

Properties: `leading`, `icon`, `reserveLeading`, `primary`, `supporting`, `expanded`, `expandedContent`, `trailing` (default
slot), `selected`, `disabled`, `interactive`, `danger`, `header`, `separator`, `accentHeader`, `focused`,
`size` (sm, md, lg), `recede`, `selectedColor`, `paintsSelection`, `headingHeight`. Read-only:
`selectionRadius`, `selectionHeight`, `expansionHeight`, `contentInset`, `hovered`, `pressed`,
`selectable`. Signals: `activated`, `hoveredEntered`. Function: `activate()`.

| State | Implemented by | Status |
| --- | --- | --- |
| rest | no box: `Surface` opacity 0 (ListRow.qml:170-171) | implemented |
| hover | `Style.tone` lift 0.4 on the surface, leading box to `rowHoverScale` (ListRow.qml:194, Motion.qml:52) | implemented |
| press | tone lift 0.8, no scale: `pressScale` stays 1 (StateLayer.qml:59) | implemented |
| focus | ring on StateLayer, only when the host binds `focused` (default false, the row takes no focus) | implemented, D7 fixed |
| selected | accent at `opacitySelected` 0.12 over surface, accent name (ListRow.qml:160-169, Style.qml:135-139) | implemented |
| disabled | colour through `Style.disabled`, row stops answering (ListRow.qml:94, 117) | implemented |
| report-only | full strength, not a target (ListRow.qml:94, 247) | implemented |
| header, separator | structural, not selectable (ListRow.qml:93, 202-229) | implemented |
| disabled and selected | fill is removed with the selection target (ListRow.qml:170-171) | see P1 |

### Routes

- Pointer: the StateLayer TapHandler (StateLayer.qml:170-183) calls `activate()` (ListRow.qml:195). The
  body and passive readings sit above it but pass the click through, so a click on them activates the
  row. A trailing action sits above both and takes its own click (ListRow.qml:307-313). Pointer entry
  emits `hoveredEntered` (ListRow.qml:196).
- Keyboard: ListRow has no key handler. The owning list routes Enter. The unit routes Enter itself
  (workbench/units/ListRow.qml:25-32, 152-155), so a list that does not is not covered by this record.
- Wheel: the row claims no wheel event (ListRow.qml and StateLayer.qml contain no wheel handler). Hosted
  content inside `expandedContent` is not examined.
- Focus: `focused` defaults to false; the owning list binds it (D7).
- Accessibility routes: `Accessible.role` Button when selectable, StaticText otherwise; name `primary`;
  description `supporting` plus Expanded or Collapsed (ListRow.qml:128-134). Judged by a11y-audit.

### Sizes, empty and long content, failure

- Row height: sm 36 (controlHeightSm 32 + space1 4), md 44 (40 + 4), lg 56 (52 + 4) (ListRow.qml:101,
  Tokens.qml:83-84, 90).
- Leading box: sm 20 (iconMd), md 24 (iconLg), lg 24 (ListRow.qml:109).
- Text: name textSm 12 at md and sm, textMd 14 at lg (ListRow.qml:284); supporting textXs 10 at md and
  sm, textSm 12 at lg (ListRow.qml:302, Style.qml:194).
- Text column left edge (`contentInset`): 12 + 24 + 8 = 44 px at md with a leading visual; 12 px
  without one (ListRow.qml:110-111).
- Empty: no leading visual hides the leading box unless `reserveLeading` is set (D1); a supporting line
  equal to the name (case-insensitive) hides; a trailing slot with no visible child that measures
  wider than 0 hides (D2).
- Long: name and supporting elide right (Prose.qml:118). The natural width is not constant; D6 is open.
- Failure and cancellation: a disabled or report-only row does not activate (ListRow.qml:94, 136-139).
  A drag past the threshold cancels the tap (StateLayer.qml:52). Collapsed expanded content takes no
  input (ListRow.qml:325).

### Visual roles and palette pairs

Source (Tokens.qml, deep-night): band `#271e30`, surface `#42394c`, text `#f0ecf5`, muted `#c5bad1`,
accent `#d9b4ea`, danger `#f5aeb7`.

Computed contrast (WCAG 2.x):

| Pair | Background | Ratio | Against |
| --- | --- | --- | --- |
| text on band | band | 13.71 | 4.5 |
| muted on band | band | 8.61 | 4.5 |
| muted on surface | surface | 5.89 | 4.5 |
| selected accent over 12% fill | surface composite | 4.74 | 4.5 |
| name at recede 0.45 | band | 3.89 | 4.5 (D4) |
| metadata at recede 0.45 | band | 2.87 | 4.5 (D4) |

Not computed: danger on band and surface, the hover-lift colour (`Style.tone` bisection), the disabled
colour (`Style.disabled`), and every other theme. The recede ratios assume the row sits on the band,
as the rollout silhouette does; a row on the surface step is not computed.

Motion (values from Tokens.qml and Motion.qml):

- Colour and opacity responses: 130 ms, OutCubic (Tokens.qml:47, Motion.qml:120).
- Press response: 80 ms (Tokens.qml:46).
- Hover scale on the leading box: 1.12 at 130 ms (Tokens.qml:64).
- Expansion reveal: 180 ms, InOutCubic, height only (ListRow.qml:328-331, Tokens.qml:49, Motion.qml:128).

Reduced motion: durations clamp (micro 60 ms, fast 80 ms, Motion.qml:26, 56). The expansion reveal is
removed (ListRow.qml:329). The hover scale is not clamped; see D9.

### Pointer geometry

Input shape: StateLayer covers the full row width and the heading height (ListRow.qml:183-186). The
painted surface has the same bounds (ListRow.qml:161-163). For md the input is 44 px tall, equal to the
painted box. The leading box's growth is visual only and is not a separate target.

Trailing action (ControlLabel): its hit box is at least `iconLg` (24 px) each way (ControlLabel.qml:13-15),
so the width is max(footprint, 24). The footprint is not measured.

Width model (assumptions, labelled):

- Row width 380 px, from `controlWidth` (Style.qml:328, Tokens.qml:86).
- Pointer at rest at the row centre, x 190, y 22 (assumption; no human average claimed).
- Trailing label footprint 64 px wide (assumption, unmeasured). Its right edge is 380 - 12 = 368, so its
  centre is at x 336 (assumption).

Row to row, vertical: D = 44 (adjacent centres; rows abut with no gap of their own), W = 44 along the
approach axis, ID = log2(1 + 44/44) = 1.00 bit. Landing tolerance ±22 px. Interference: none from the
row itself. The expanded content lies outside the StateLayer, so a pointer over it neither activates nor
hovers the row.

Trailing "Details", horizontal from the centre: D = 336 - 190 = 146 px, W = 64 px (assumed), ID =
log2(1 + 146/64) = 1.71 bits. Vertical tolerance for the action is ±12 px (its 24 px hit height, centred
by ListRow.qml:310), against ±22 px for the row body. A press 13 to 22 px above or below the centre
activates the row, not the action. This is source-derived and unmeasured.

Popup corridor: not applicable to the row itself. A rollout that hosts it owns the corridor.

### Findings

Source-backed defects are listed in the structured result with their fix. Redesign proposals and taste
are in the structured result as P-items. The two source conflicts and the hypotheses are below.

Fix status (source-reviewed and load-checked with one capture of `list-row`; not runtime-exercised, not
owner-accepted):

- D1 fixed: `reserveLeading` (default false) keeps the leading box for a row with no visual, so a list
  that mixes rows chooses the stable edge; the default behaviour is unchanged. SC2 stays the owner's.
- D2 fixed: the trailing slot shows only when a visible child has a width. The unit's always-present
  empty Loader is now hidden outside the device variant, since a zero-width child in a Layout still
  adds its spacing.
- D3 fixed: the separator's y is rounded.
- D5 fixed: a hovered or pressed row is at full strength.
- D7 fixed: `focused` defaults to false and the host binds it.
- D6 open: a constant natural width collapses `Menu.implicitWidth`, which sizes itself by the widest
  row; `Menu` has to take its width from a constant first.

Source conflicts (the owner rules):

- SC1: the recede token `opacityRecede` 0.45 (Tokens.qml:72) against the 4.5:1 floor for body text
  (ui-audit pass 4). The minimum alpha that holds 4.5:1 for the name on the band is 0.503; for the
  metadata line it is 0.654 (computed). D4 carries the choice.
- SC2: the leading-box comment (ListRow.qml:16-22) says the box is reserved so the name's edge does not
  move between rows; the AGENTS slot law says an empty slot takes no space. D1 carries the choice.

Hypotheses (observed in source, not measured; not in the table):

- H1: the StateLayer HoverHandler (StateLayer.qml:164-168) is a sibling of the surfaces, not their
  ancestor, which the AGENTS hover-reader law advises against. The law's failure case is a sibling above
  the surface; this one sits below the body and above the surface. Unmeasured.
- H2: the body (ListRow.qml:232) reads no hover, so the pointer over the trailing action may still set
  StateLayer `hovered`, lifting the row under the action. Unmeasured.
- H3: the focus ring reaches 4 px beyond the row's own left and right edges (StateLayer.qml:147-150). A
  host that clips at the row edge cuts the ring. Depends on the host; unmeasured.
- H4: the text column (ListRow.qml:277) and the header label and rule (ListRow.qml:212-218) have no
  `Layout.alignment`, while the leading box and trailing slot centre theirs. Whether the name centres
  vertically depends on Qt's default, which is not verified here.
- H5: `visible` on the leading box and trailing slot reads `children.length` (ListRow.qml:259, 312). If
  `children` does not notify, a child added after creation leaves the slot hidden. Unverified.
- H6: recede is opacity on a composite (ListRow.qml:247-249), the case the AGENTS composite law names
  for disabled. No overlapping translucent child exists in this file, so the law is not broken yet.
- H7: `_headingHeight` reads `root.height` for rows without expanded content (ListRow.qml:104-105). No
  loop was found, because `implicitHeight` does not read it, but a host's `height` becomes the selection
  area without a stated contract.

Not examined: any runtime state, tree, or capture; themes other than deep-night; scale factors; the
disabled and danger contrast; the hover-lift colour; sm and lg rendered; wheel through hosted content in
`expandedContent`. Caelestia: `Menu.qml` (read to line 170) keeps unselected items at full strength and
marks the active one with a container fill; no dimming of unselected items appears in what was read.
