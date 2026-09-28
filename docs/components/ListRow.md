# ListRow

A fixed-height line of information or one command in launcher results and popout lists; the host owns selection, values and the action's consequence.
states: rest, hover, press, focus, selected and disabled; informational rows stay full-strength and non-interactive, disabled applies only when an existing action is unavailable, and selected remains visible through hover.
actions: pointer click and `activate()` emit `activated`; keyboard navigation and activation belong to the owning list, and a trailing action emits its own intent without activating the row.
pointer: the row is a single target when interactive; a trailing action has its own hand target, hover reports intent, and wheel is not claimed.
keyboard: the owning list holds focus and routes arrow/Enter navigation; its current enabled row receives the focus ring on the row body rather than on a child.
screen reader: the primary label names the selectable row, supporting text describes it, and a trailing action supplies its own name.
size: sm, md and lg resolve through the row/control height scale; leading and trailing slots scale with the row while the radius and focus gap stay constant; content elides rather than growing height.
tokens: control-height, icon and type scales, space scale, surface ladder, accent, `Style.disabled`, Motion and StateLayer; no local colours or measurements.
motion: micro colour and state response, no position animation during a gesture; reduced motion shortens the duration.
not designed: multi-selection, nested disclosure, confirmation, asynchronous progress or a menu; those belong to the host or a specialized child.
