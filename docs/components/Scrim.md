# Scrim

The ground going quiet behind something that has taken over; it dims what is behind and catches the pointer so a modal is modal in behaviour, not just appearance.
states: shown and hidden with an opacity fade between them (`Motion.medium` in, `Motion.exit` out, standard and exit easing); hidden removes itself from the scene so it never eats clicks meant for the surface underneath.
actions: `dismiss()` and a click with any button report `dismissed` while shown and `dismissible` (it follows `enabled` until a host states it); the surface decides what that means. Neither route changes `shown`.
pointer: while painted, fade out included, it takes the click, the hover and the wheel of every button, so nothing beneath it answers; `dismissible: false` stops the report and still catches. `enabled: false` is not a refusal: a disabled item stops receiving events and the ground would hear them.
keyboard: none; Escape belongs to the modal content, never to the dim.
screen reader: decoration (`Accessible.ignored`); the modal content names itself.
size: fills its parent; no preset and no natural size.
tokens: band and `Style.scrimOpacity` for the dim, the medium Motion set with standard entry and exit easing; no local colours or measurements.
motion: opacity only; reduced motion shortens the duration.
expected: shell Workbench → Scrim: the output list dims when shown and answers hover, click and wheel when hidden; shown, a click on a row dismisses and the row never hears it, `dismissal: refused` catches without dismissing.
not designed: modal content, focus trapping or dismissal policy; use Dialog, Popover or the host for those.

Measured (default theme, 1.25 scale, headless window): shown over an output list, the row under the pointer does not hover, the wheel does not scroll the list, a click 40 ms into the fade-out does not reach the row, and `dismissible: false` catches without reporting (flow scrim-catch). The dim moves the ground from #3b3145 to #302639, 1.15:1; the ground's text falls to 3.47:1 on the dimmed ground, which is the point (it is inactive).
