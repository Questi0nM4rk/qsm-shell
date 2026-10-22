# EmptyState

A centred icon, title and detail with one action slot for content that has nothing to show; it explains the void and offers the way out.
states: none; icon, detail and action sections each collapse when empty (the action section when the slot holds no visible item), and `title` is always present.
actions: none of its own; the consumer's recovery control rides the default `action` slot.
pointer: none on the message itself; the slotted control keeps its own target and wheel passes through.
keyboard: none on the message itself; the slotted control keeps its own tab stop and keys.
screen reader: a group named by the title and described by the detail; the glyph is decoration and the slotted action names itself.
reference: shadcn/ui's Empty keeps media, title and description in one header apart from the content that holds the action (https://ui.shadcn.com/docs/components/empty); the spacing follows that grouping.
size: a column never wider than `controlWidth`, so a long title elides and a long detail wraps instead of pushing past the surface that holds it (a host sets no width). Spacing groups by proximity: glyph to title `space3`, title to detail `space1`, detail to action `space4`.
tokens: space1, space3, space4, space2, iconLg, controlWidth, textMuted and Prose; no local colours or measurements.
motion: none; an empty surface never implies interactivity through motion.
measured (rendered, scale 1.25): title 13.71:1 and detail 8.50:1 on the band; a 190-character reading with a 70-character title is 380 px wide and 123 px tall, three wrapped lines; the glyph, title, detail and action share one centre line.
not designed: loading shells, error copy with tone or inline field hints; use Skeleton, Callout or Field for those.
