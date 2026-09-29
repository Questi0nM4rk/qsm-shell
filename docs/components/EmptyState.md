# EmptyState

A centred icon, title and detail with one action slot for content that has nothing to show; it explains the void and offers the way out.
states: none; icon, detail and action sections each collapse when empty, and `title` is always present.
actions: none of its own; the consumer's recovery control rides the default `action` slot.
pointer: none on the message itself; the slotted control keeps its own target and wheel passes through.
keyboard: none on the message itself; the slotted control keeps its own tab stop and keys.
screen reader: title names the state and detail describes it; the slotted action names itself.
size: content-driven column with fixed spacing; the glyph is icon large and the text is centred title and muted body.
tokens: space2, iconLg, textMuted and Prose; no local colours or measurements.
motion: none; an empty surface never implies interactivity through motion.
not designed: loading shells, error copy with tone or inline field hints; use Skeleton, Callout or Field for those.
