# KeyValueRow

A compact label and reading pair for device and status lines; it shows the truth at full strength and is simply not a target.
states: none; it is never hovered, pressed, focused, selected or disabled, and dimming it would misreport a live reading as stale.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: one static text read as "label: value"; the two texts inside it are ignored.
size: one glyph step (`iconSm`, 16 px) tall whether or not there is a glyph, `controlWidth` wide by default; label and value both fill and elide together when the line is short, so neither squeezes the other; the value is right-aligned.
tokens: space2, iconSm, text and textMuted; no local colours or measurements.
motion: none.
expected: setting, replacing or clearing `icon` after construction re-lays out the actual row before the next rendered frame; label and reading never overlap the glyph. No unit-side reconstruction or extra spacing compensates for it.
source: Qt RowLayout owns the optional glyph's participation and spacing; compare live geometry after render polish, not during the property-write stack. Caelestia has no corresponding passive label/value row. The native rendered-frame regression covers empty/populated/empty changes.
not designed: selection, action or editing; use ListRow, a slot action or the host for those.

## Measured

Unit `key-value` in a headless slot at scale 1.25, 380 px wide:

- Every row is 16 px tall (`iconSm`), with or without a glyph; rows 4 px apart sit on a 20 px step. The glyph is 16 px, the label starts at x 24, the value is right-aligned to the row's right edge.
- Label and value share a line that is too short: label 172 px and value 176 px, both elided ("Remaining battery charge...", "87% (about 3 hours 42 m..."); a value never squeezes its label to a few letters.
- Label and value read as one phrase, "Battery: 87%", with the two texts ignored.
