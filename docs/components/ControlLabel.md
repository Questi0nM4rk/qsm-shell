# ControlLabel

The one label element that names a control from outside; Field puts it above a text box and Slider wears it on any of four sides.
states: rest and disabled through `Style.disabled`; `clickable` true makes the control an action surface, off it is a caption.
actions: `activate(): bool` and its named `activate` Action share `clicked` with pointer, keyboard and accessibility activation when clickable, enabled and nonempty. Icon, text and required are properties; content inside a control belongs to the control itself.
pointer: a clickable label overflows a hit box of at least icon size around its footprint instead of growing it; a caption claims nothing.
keyboard: actionable labels alone join Tab/Backtab traversal; Enter, Return and Space activate once per press. Focus or availability/content loss cancels a held activation.
screen reader: actionable labels expose Button press and caller-owned `accessibleName` (defaults to text); passive labels remain supporting caption text. The required mark is a non-colour channel.
size: `sizeScale` from the owning control scales text, glyph and gap through the Style helpers; the hit box never moves neighbouring content.
tokens: textSm, iconSm, iconLg, space1, textMuted, danger, radiusSm and StateLayer; no local colours or measurements.
motion: StateLayer response only when clickable; no local animation.
expected: public, pointer, keyboard and accessibility activation share one guarded operation; disabled, caption and empty-label cases report no intent. Actionable labels are keyboard reachable without changing layout footprint; passive captions add no Tab stop.
not designed: input, validation copy or layout; use Field, the control itself or the host for those.
