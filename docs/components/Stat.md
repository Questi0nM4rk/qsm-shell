# Stat

A single value metric with trend semantics; it reads one number and which way it is moving.
states: none beyond its facts; trend up or down colours only when a `good` direction names the winner (default `none`, muted), and an unwelcome trend adds a warning glyph so the cue is not hue alone. A figure with no reading shows a quiet dash and no unit or trend, because those would describe nothing.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: one static readout named as the whole figure, "label, value and unit, direction, better or worse" (for example "CPU, 72%, rising, worse"; "CPU, no reading"); the parts are never read separately.
errors: an unknown `trend` or `good` logs a `console.error` naming the property and value; the trend glyph is then not drawn.
size: constant natural width `contentWidth` (default `Style.statWidth`, 140); everything sits at the start of its row, so a short reading never spreads the unit and glyphs across the width; a long value or label elides inside it. The unit is half the reading's size on its baseline (title under display, heading under hero); value and unit share the technical face. Rows are 4 px apart.
contrast: text, textMuted, success and warning clear 4.5 on band, surface and overlay (success 9.41, 7.23, 5.51; warning 9.13, 7.01, 5.34); the two hues are 1.03 apart, so the warning glyph carries the difference.
tokens: spaceTight, space1, statWidth, iconSm, iconXs, textMuted, success and warning; no local colours or measurements.
motion: none.
not designed: charts, selection or editing; use Sparkline, ListRow or the host for those.
