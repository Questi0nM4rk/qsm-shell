# Dialog

A modal takeover that dims the ground, traps focus and returns it on close; the surface that opened it owns dismissal policy.
states: open and closed; open fades and settles the card in, close exits it out; the card keeps its shape while invisible so layout never jumps.
actions: slotted controls in the default `actions` slot; Escape and the scrim only report `dismissed`, and close restores focus and emits `closed`.
pointer: the scrim catches every button so nothing reaches the surface behind; the card keeps its own targets and wheel passes through to content.
keyboard: focus moves into the card on open and back to the captured item on close; head and tail sentinels trap tab inside while open.
screen reader: the card is the focused scope; title and body are heading and body text, and slotted actions name themselves.
size: fixed `dialogWidth` with content-driven height; double container margins, radius `radiusXl`; the action row trails in reading order.
tokens: controlWidth, space5, space3, space2, iconMd, radiusXl, overlay, accent, danger, warning and Prose; no local colours or measurements.
motion: medium opacity and scale settling with emphasized entry and exit curves; reduced motion shortens the duration.
not designed: modeless popovers, inline messages, form fields or dismissal policy; use Popover, Callout, Field or the host for those.
