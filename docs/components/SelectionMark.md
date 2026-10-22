# SelectionMark

The pure visual tick that marks the current row of a list; the row owns the semantics and the mark only shows them.
states: hidden and shown; `strong` marks the keyboard-current row wider, in the same colour, because brightness is already spoken for.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and the wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; the owning row carries the name and the selected state.
size: `Style.markThickness` wide (`strong` adds `Style.indicatorWidth`), `Style.markHeight` tall, pill radius, both widths a whole number of device pixels; hidden collapses height and opacity together. The consumer positions it in the row's own layout.
tokens: markThickness, markHeight, indicatorWidth, radiusPill, accent, Motion and `Style.stroke`; no local colours or measurements.
motion: one curve both ways, `Motion.micro` on the emphasized curve for the height and the standard curve for the opacity; widening takes `Motion.micro` on the move curve. Reduced motion shortens all of them. A departure that eased in (`Motion.exitEasing`) would hold the old mark on screen while the next lands, so there is none; a Behavior also reads its duration before a `shown ? a : b` binding in it has re-evaluated, so such a branch never ran (a 600 ms departure still finished in 71 ms).
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
| arrival, height to 90 %, sampled every 4 ms | 72 ms (token 130, ease-out, frames 17 ms apart in the offscreen renderer) |
| departure, height to 10 % | 71 ms, the same curve as the arrival |
