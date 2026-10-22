# Callout

A persistent inline message with a recovery action; the host owns the condition, the copy and what the action does.
states: info, success, warning and danger; tone sets the rule, the glyph and the surface tint together, never colour alone; title, body and action sections collapse when empty (an empty action host adds no gap, and a body-less callout keeps its action beside the mark); an unknown tone or a missing icon file reports on the error stream.
actions: none of its own; the consumer's recovery controls ride the default `actions` slot.
pointer: none on the message itself; slotted controls keep their own targets and wheel passes through.
keyboard: none on the message itself; slotted controls keep their own tab stops and keys.
screen reader: warning and danger are an alert message, info and success a note, named by the title and described by the body; icon, hue and rule carry the tone as three channels.
reference: Radix Themes' Callout takes `role="alert"` when the message needs attention (https://www.radix-ui.com/themes/docs/components/callout); warning and danger do.
size: natural width is the constant `controlWidth` and a host sets `width`; the title elides on one line, the body wraps and the height follows it; content sits `space3` from the rule and the other three edges, the rule is one mark width and starts where the corner arc meets the edge, radius is `radiusBody`; the mark centres on the first line of copy.
tokens: space3, space1, space2, iconMd, radiusBody, markThickness, calloutTintOpacity, the semantic tone set and Prose; no local colours or measurements.
motion: none; a persistent message never implies interactivity through motion.
measured (rendered, scale 1.25): title 8.4 to 8.5:1 and body 5.2 to 5.3:1 on every tone; content 12 px from top, right and bottom and 12 px from the rule's inner edge; the mark centres within 0.5 px of the first line; the action sits one `space1` below the copy, or one `space3` from the mark when there is none.
not designed: dismissal, transient toast behaviour, progress or form input; use NotificationCard, EmptyState or Field for those.
