# SvgIcon

A non-interactive semantic glyph renderer for the shell's icon vocabulary; a parent action or label owns all input and accessible interaction.
states: rest inherits its supplied `color`; disabled, selected, danger and loading colours are decided by the owning component through `Style`, never hidden in the glyph; `ready` reports that the glyph is on screen (false for an empty name and while one loads).
actions: none; pointer, keyboard and wheel pass through, and SvgIcon never claims focus.
screen reader: no role of its own and never a second target; a standalone meaningful icon is named by its owning control.
size: the caller supplies one `size` from the icon scale (12, 16, 20, 24, 32, 44); the painted glyph is square and bounded by that size regardless of its source viewbox.
set: one 24 px stroke set normalised to a white stroke so the tint is exact; weather has `cloud`, `rain`, `snow` and `fog` beside `moon`, `sunset` and `thermometer`. A name with no file logs one error naming it and draws nothing.
tokens: caller-selected icon scale and semantic foreground role; no local colour, padding or hit target. Text and graphic contrast of the roles on band, surface and overlay: text 13.71, 10.53, 8.02; accent 8.87, 6.82, 5.19; danger 8.84, 6.79, 5.17.
motion: no local motion; state changes belong to the owner.
not designed: clickable icons, badges, image thumbnails or arbitrary SVG documents; use IconButton, Badge, Image or a specialized component.
