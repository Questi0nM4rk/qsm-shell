# SelectionMark

The pure visual tick that marks a selected row; the row owns the semantics and the mark only shows them.
states: hidden and shown; `strong` marks the keyboard-current row wider and opaque while a resting tick dims through `restOpacity`.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; the owning row carries the selectable name and state.
size: mark thickness by mark height with pill radius; hidden collapses height and opacity together; the consumer positions it in the row layout.
tokens: markThickness, markHeight, spaceTight and accent; no local colours or measurements.
motion: micro height, opacity and width settling with emphasized and exit curves; reduced motion shortens the durations.
not designed: selection state, focus or activation; use ListRow, Menu or the host for those.
