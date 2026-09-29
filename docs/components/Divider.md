# Divider

One thin line; decorative separation and nothing else.
states: none; it is never hovered, pressed, focused, selected or disabled.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; a decorative rule with no accessible name.
size: implicit height is its own thickness; the drawn line insets symmetrically so anchored and fixed-width consumers behave alike; the item may claim a gap while the ink stays one pixel.
tokens: outline, space3 and the strength fraction; `lineColor` and `thickness` remain overrides for foreign grounds such as a band.
motion: none.
not designed: labelled separators, interactive structure or spacing; use ListRow header rows, Section or layout gaps for those.
