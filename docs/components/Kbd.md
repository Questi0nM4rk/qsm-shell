# Kbd

A keyboard shortcut drawn as caps joined by `+`; a physical object the person knows from the world, scanned against the keyboard rather than read.
states: none; it is never hovered, pressed, focused, selected or disabled.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and the wheel passes through.
keyboard: none; it describes keys and takes none, and is never a tab stop.
screen reader: one StaticText named by the whole `combo`; the caps and joins are not announced one by one, so a host does not repeat the name.
size: a cap is at least `Style.space5` wide and `Style.badgeHeight + Style.space1` tall, its text plus `Style.space2` up to the next step of the 4 px rhythm; a join is a `Style.space4` slot with its "+" centred, and caps and joins touch. Qt Layouts put a child on a whole logical pixel and at 1.25 only a multiple of 4 is also a whole device pixel, so a natural combo sits on the grid wherever its host puts it on a multiple of 4. The host owns the width: left alone Kbd is as wide as its caps; a narrower one shrinks the caps and elides their text, the joins keep their slot, and one narrower than the smallest caps and joins cuts what does not fit at its edge.
tokens: space5, space4, space2, space1, badgeHeight, radiusXs, keycap, text roles and `Style.snap`; no local colours or measurements.
motion: none.
not designed: input, shortcut handling, editing, or a size preset (the type floor of 12 and the cap height are fixed); a combo with no parts draws nothing.

## Contract

- Public: `combo` (required) and `minCapWidth`. `combo` splits on `+`, trims each part and drops empty parts, so a compositor's own bind string renders as written.
- The cap fill is `Style.keycap`, 0.9 above the band, so a cap reads the same on the band, on a card and on a popout.
- The unit (`workbench/units/Kbd.qml`) is a keybind column: short, modifiers and long combos in a natural, a narrow (112 px) or a tight (72 px) column; its flow checks the name, that no cap is elided at natural width (also after a squeeze), the shrink and the cut.

## Measured at scale 1.25

| what | value |
| --- | --- |
| SUPER + SHIFT + Q, natural | 152 x 20: caps 48, 48, 24, joins 16 (before 145: caps 45.09, 44.09, 24, joins 10.05 and 2 px spacing) |
| cap edges off the device grid, 6 edges | 0 (before 3: 0.75, 0.12 and 0.12 of a device pixel off) |
| a cap's text against its cap, at natural width | none elided (an earlier rounding to the nearest device pixel left SHIFT 0.1 px narrow and Qt cut it to "SHI...") |
| three caps in a 112 px column | 112 px, caps 28, 28, 24, text elided; reach past the column 0 px (before 33) |
| three caps in a 72 px column | cut at the column edge, a sliver of the last join shows |
| cap text on cap, rendered | 7.25:1 |
| join on band | 8.61:1 |
| cap on band | 1.89:1 (the cap's shape carries no meaning the text does not) |
