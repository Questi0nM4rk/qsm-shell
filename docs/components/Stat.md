# Stat

A single value metric with trend semantics; it reads one number and which way it is moving.
states: none beyond its facts; trend up, down or flat colours only when a `good` direction names the winner, otherwise muted.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: value, label and unit are plain text roles; the trend glyph repeats the coloured fact in shape.
size: content-driven column with tight spacing; value, reading and metadata roles with small label and trend glyphs.
tokens: spaceTight, space1, iconSm, iconXs, textMuted, success and warning; no local colours or measurements.
motion: none.
not designed: charts, selection or editing; use Sparkline, ListRow or the host for those.
