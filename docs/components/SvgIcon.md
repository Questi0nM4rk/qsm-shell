# SvgIcon

A non-interactive semantic glyph renderer for the shell's icon vocabulary; a parent action or label owns all input and accessible interaction.
states: rest inherits its supplied `color`; disabled, selected, danger and loading colours are decided by the owning component through `Style`, never hidden in the glyph.
actions: none; pointer, keyboard and wheel pass through, and SvgIcon never claims focus.
screen reader: decorative by default when beside an accessible label; a standalone meaningful icon must be named by its owning control, not duplicated as a second target.
size: the caller supplies one `size` from the icon scale; the painted glyph is square and remains bounded by that size regardless of its source SVG viewbox.
tokens: caller-selected icon scale and semantic foreground role; no local colour, padding or hit target.
motion: no local motion; state changes belong to the owner.
not designed: clickable icons, badges, image thumbnails or arbitrary SVG documents; use IconButton, Badge, Image or a specialized component.
