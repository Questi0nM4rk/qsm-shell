# ControlLabel

The one label element that names a control from outside; Field puts it above a text box and Slider wears it on any of four sides.
states: rest and disabled through `Style.disabled`; `clickable` true makes it the control's action surface, off it is a caption and takes no pointer.
actions: `clicked` when clickable; icon, text and required are properties, never slots; content inside a control belongs to the control itself.
pointer: a clickable label overflows a hit box of at least icon size around its footprint instead of growing it; a caption claims nothing.
keyboard: none of its own; the named control keeps its tab stop and keys.
screen reader: no role of its own; it is supporting text for the control it names, and the required mark is a non-colour channel.
size: `sizeScale` from the owning control scales text, glyph and gap through the Style helpers; the hit box never moves neighbouring content.
tokens: textSm, iconSm, iconLg, space1, textMuted, danger, radiusSm and StateLayer; no local colours or measurements.
motion: StateLayer response only when clickable; no local animation.
not designed: input, validation copy or layout; use Field, the control itself or the host for those.
