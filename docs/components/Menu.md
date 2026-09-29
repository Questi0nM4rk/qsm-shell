# Menu

A keyboard-navigable container for rows; the host owns the model, the delegate and what activation does.
states: one `currentIndex` cursor over selectable rows; non-selectable entries are stepped past and activation wraps across them.
actions: `step(delta)` moves the cursor and `activateCurrent()` fires `activated(index)`; static content and model with delegate both feed the same rows.
pointer: rows keep their own targets; the container claims no clicks and wheel passes through.
keyboard: arrows step along the orientation and Return and Enter activate the current row; the container holds focus for its rows.
screen reader: rows name themselves; the container adds no role beyond grouping.
size: rows stretch across the container on the cross axis; fixed spacing binds them; the container follows its rows.
tokens: space1 only; rows bring their own type, icon and space scales.
motion: none of its own; rows settle their own state changes.
not designed: the row itself, popover placement or dismissal; use ListRow, Popover or the host for those.
