# ListRow

The row: one line in a list of things a person picks from; the host owns selection, values and the action's consequence.
states: rest, hover, press, focus, selected, disabled and report-only; header and separator are structural rows a cursor steps past; disabled dims an unavailable action while a report-only row stays full-strength and simply is not a target; recede dims unpicked rows only in lists you pick from.
actions: `activate()` guards selectable and emits `activated`; StateLayer click, pointer, keyboard and programmatic routes share it; `pulse()` punches the mark when selection moves; keyboard navigation and focus belong to the owning list through `focused`.
pointer: the StateLayer sits before the content and grows the leading box only, so a trailing click is never swallowed; hover reports `hoveredEntered` for the list cursor and wheel is not claimed.
keyboard: the owning list holds focus and routes arrows and Enter; the current row shows the focus ring on the body and the mark scales on pulse.
screen reader: selectable rows announce as buttons named by the primary label with supporting text as description; structural and report-only rows are static text.
size: sm, md and lg resolve through the control-height scale with the leading box at one fixed size per row; the asked width includes the inset the body gives away; long text elides and a supporting line that repeats the name hides.
tokens: control-height, icon and type scales, space scale, mark roles, opacity roles, surface ladder, accent, danger, Motion and StateLayer; no local colours or measurements.
motion: micro colour and opacity response plus the emphasized mark pulse; no position animation during a gesture; reduced motion shortens the durations.
not designed: multi-selection, nested disclosure, confirmation, asynchronous progress or a menu; those belong to the host or a specialized child.
