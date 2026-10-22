# ProgressBar

A thin determinate or indeterminate progress line; it shows a fraction or ongoing work and takes no input.
states: determinate fill by clamped value; indeterminate band sweeping across an empty track; disabled is a still, dimmed track (no band, no travel) through `Style.disabled`.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: role ProgressBar, named by `accessibleName` (empty by default: the surface that started the work names it); the description is the percentage while determinate and empty while indeterminate.
size: fixed track thickness (`trackThickness` in whole device pixels) with pill radius; no natural length: the host states it, and the bar fills it; the band is three tenths of the length.
tokens: trackThickness, primary (the active part of a track), overlay, Style.disabled; no local colours.
motion: fast width settling on value change (removed under reduced motion); a looping sweep while indeterminate, enabled and visible, period `Motion.spin * 2` (lengthened under reduced motion); eased at both ends so it does not read as a conveyor belt.
not designed: metering a level, staging steps or labelling; use Meter, Stepper content or Prose for those.

## Measured

Slot at scale 1.25: track 4 px (5 device), 380 px long in the unit. Fill on track 5.19:1, track on band 1.71:1 (the ladder's inactive-track role; a 3:1 track is an owner ruling). Indeterminate sweep: 61 fps, no gap over 17 ms; the disabled bar commits 1 frame in 2 s (it was 118). The band is clipped square at the track ends, one device pixel wider than the pill's nub there.
