# SelectionMark

The pure visual tick that marks the current row of a list; the row owns the semantics and the mark only shows them.
states: hidden and shown; `strong` marks the keyboard-current row wider, in the same colour, because brightness is already spoken for.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and the wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; the owning row carries the name and the selected state.
size: `Style.markThickness` wide (`strong` adds `Style.indicatorWidth`), `Style.markHeight` tall, pill radius, both widths a whole number of device pixels; hidden collapses height and opacity together. The consumer positions it in the row's own layout.
tokens: markThickness, markHeight, indicatorWidth, radiusPill, accent, Motion and `Style.stroke`; no local colours or measurements.
motion: an arrival grows in `Motion.micro` with the emphasized curve; a departure shortens by `Motion.exit` (80 %) on the exit curve; widening takes `Motion.micro`. Reduced motion shortens all of them.
not designed: selection state, focus, activation, a dimmed resting level or a mark that is always present; the row owns them.

## Contract

- Public: `shown`, `strong`, `markColor`.
- A host disabling the row passes `markColor: Style.disabled(Style.accent)`.
- The unit (`workbench/units/SelectionMark.qml`) is three rows with a current one, none or any of them, normal or strong; the flow waits for the settled heights.

## Measured at scale 1.25

| what | value |
| --- | --- |
| mark | 3.2 x 18 (4 device px wide), strong 4.8 x 18 (6 device px) |
| mark centre against its row label centre | 0 px |
| mark left inset, label inset | 4 px, 16 px |
| accent on band | 8.87:1 |
| departure, recorded frames at 60 fps (16.4 ms apart) | 82 ms to zero before `Motion.exit`, 65 ms after |
| arrival, same frames | height settled within 66 ms |
