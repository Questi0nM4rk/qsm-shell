# Kbd

A keyboard shortcut drawn as caps joined by `+`; a physical object the person knows from the world, scanned against the keyboard rather than read.
states: none; it is never hovered, pressed, focused, selected or disabled.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and the wheel passes through.
keyboard: none; it describes keys and takes none, and is never a tab stop.
screen reader: one StaticText named by the whole `combo`; the caps and joins are not announced one by one, so a host does not repeat the name.
size: a cap is at least `Style.space5` wide and `Style.badgeHeight + Style.space1` tall, sized to its text plus `Style.space2`, every width a whole number of device pixels. The host owns the width: left alone Kbd is as wide as its caps; a narrower one shrinks the caps and elides their text, the joins keep theirs, and one narrower than the smallest caps and joins cuts what does not fit at its edge.
tokens: space5, space2, spaceTight, badgeHeight, space1, radiusXs, keycap, text roles and `Style.snap`; no local colours or measurements.
motion: none.
not designed: input, shortcut handling, editing, or a size preset (the type floor of 12 and the cap height are fixed); a combo with no parts draws nothing.

## Contract

- Public: `combo` (required) and `minCapWidth`. `combo` splits on `+`, trims each part and drops empty parts, so a compositor's own bind string renders as written.
- The cap fill is `Style.keycap`, 0.9 above the band, so a cap reads the same on the band, on a card and on a popout.
- The unit (`workbench/units/Kbd.qml`) is a keybind column: short, modifiers and long combos in a natural, a narrow (112 px) or a tight (72 px) column; its flow checks the name, the shrink and the cut.

## Measured at scale 1.25

| what | value |
| --- | --- |
| caps SUPER, SHIFT, Q: widths | 44.8, 44, 24 (56, 55, 30 device px) |
| cap edges off the device grid, before and after | 3 of 3 (up to 0.36 device px), 0 of 3 |
| three caps in a 112 px column: reach past the column | 33 px before, 0 px after (caps 28, 29, 24, text elided) |
| three caps in a 72 px column | 73 px before, 32 px after, cut at the column edge |
| six caps in a 112 px column | 254 px before, 114 px after, cut at the column edge |
| cap text on cap, rendered | 7.25:1 |
| join on band | 8.61:1 |
| cap on band | 1.89:1 (the cap's shape carries no meaning the text does not) |
