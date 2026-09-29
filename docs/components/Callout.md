# Callout

A persistent inline message with a recovery action; the host owns the condition, the copy and what the action does.
states: info, success, warning and danger; tone sets the rule, the glyph and the surface tint together, never colour alone; title, body and action sections collapse when empty.
actions: none of its own; the consumer's recovery controls ride the default `actions` slot.
pointer: none on the message itself; slotted controls keep their own targets and wheel passes through.
keyboard: none on the message itself; slotted controls keep their own tab stops and keys.
screen reader: icon, hue and rule carry the tone as three channels; title and body are plain text roles.
size: content height plus double box inset; the rule is one mark width; radius is `radiusMd`; content never grows beyond its text and slots.
tokens: space3, space1, space2, iconMd, radiusMd, markThickness, the semantic tone set and Prose; no local colours or measurements.
motion: none; a persistent message never implies interactivity through motion.
not designed: dismissal, transient toast behaviour, progress or form input; use NotificationCard, EmptyState or Field for those.
