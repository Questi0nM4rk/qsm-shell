# Scrim

The ground going quiet behind something that has taken over; it dims what is behind and catches the pointer so a modal is modal in behaviour, not just appearance.
states: shown and hidden with an opacity fade between them; hidden removes itself from the scene so it never eats clicks meant for the surface underneath.
actions: none of its own; any click reports `dismissed` and the surface that opened it decides whether clicking away is allowed.
pointer: catches every button while shown so no click reaches the surface behind; wheel handling stays with the content above.
keyboard: none; Escape belongs to the modal content, never to the dim.
screen reader: no role of its own; the modal content names itself.
size: fills its parent; no preset and no natural size.
tokens: background and the medium Motion set with standard entry and exit easing; no local colours or measurements.
motion: medium opacity fade; reduced motion shortens the duration.
not designed: modal content, focus trapping or dismissal policy; use Dialog, Popover or the host for those.
