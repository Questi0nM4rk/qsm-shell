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
not designed: selection, action or editing; use ListRow, a slot action or the host for those.
