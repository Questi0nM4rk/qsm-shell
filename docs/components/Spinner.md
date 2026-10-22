# Spinner

An animated progress affordance for ongoing work with no knowable end; it turns while running and takes no input.
states: running, stopped (the unlit ring only: a frozen arc would read as a fraction) and hidden (the turn stops with `visible`; `turning` reports it).
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: role ProgressBar, named by `accessibleName` (empty by default: the surface that started the work names it); no value, because none is known.
size: one `size` square from the icon scale (default `iconMd`); the stroke is `spinnerStrokeRatio` of the box in whole device pixels and sits inside the box.
tokens: iconMd, spinnerStrokeRatio, ringTrackOpacity, primary, Motion.spin; no local numbers.
motion: the lit arc turns linearly (one transform per frame) over a faint full ring with round caps; both are vector (`Shape`, curve renderer), so edges are drawn at the window's resolution; reduced motion lengthens the period to 1800 ms.
not designed: fractions, metering a level or labelling; use ProgressBar, Meter or Prose for those.

## Measured

Slot at scale 1.25, 24 px box. Ring edge along the centre row: 2 soft pixels per edge from the old Canvas bitmap (stretched from 24 to 30 device pixels), now 1 near-full pixel; stroke 3.84 px (4.8 device) now 4 px (5 device). Recording 61 fps, no gap over 17 ms, one turn 900 ms. Arc on band 8.87:1, unlit ring on band 1.50:1 (decorative remainder). The screen-reader row is read from source: the AT-SPI bus is not available in the slot.
