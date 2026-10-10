# ListRow

The row: one item a person operates repeatedly; the host owns selection, values, optional inline expansion and the action's consequence. Activating an item never means advancing selection.
states: rest, hover, press, focus, selected, disabled and report-only; header and separator are structural rows a cursor steps past; disabled dims an unavailable action while a report-only row stays full-strength and simply is not a target; recede dims unpicked rows only in lists you pick from.
actions: `activate()` guards selectable and emits `activated`; StateLayer click, pointer, keyboard and programmatic routes share it; `pulse()` punches the mark when selection moves; keyboard navigation and focus belong to the owning list through `focused`.
pointer: StateLayer grows the leading box only; clickable trailing actions take their own grab, while passive readings remain part of the row target; hover reports `hoveredEntered` for the list cursor and wheel is not claimed.
keyboard: the owning list holds focus and routes arrows and Enter; the current row shows the focus ring on the body and the mark scales on pulse.
expected: the single-row unit owns focus and routes Enter through `activate()`; a physical trailing-action click reports only that action, body and passive-reading clicks activate the row, and long-content mode keeps both routes judgeable. Menu composition / Shell items hosts interaction between multiple rows and their editors; the row unit never implements a selector.
screen reader: selectable rows announce as buttons named by the primary label with supporting text as description; structural and report-only rows are static text.
size: sm, md and lg resolve through the control-height scale with the leading box at one fixed size per row; `headingHeight` is the host's absolute-height escape hatch, keeping body/input/editor origin aligned; readonly `expansionHeight` reports the actual revealed viewport for bounded surface sizing. Hosts never override total implicitHeight to set a heading. The asked width includes the inset the body gives away; long text elides and a supporting line that repeats the name hides.
tokens: control-height, icon and type scales, space scale, mark roles, opacity roles, surface ladder, accent, danger, Motion and StateLayer; no local colours or measurements.
motion: micro colour and opacity response plus the emphasized mark pulse; no position animation during a gesture; reduced motion shortens the durations.
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
