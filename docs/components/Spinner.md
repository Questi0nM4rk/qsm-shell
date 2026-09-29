# Spinner

An animated progress affordance for ongoing work without a fraction; it spins while running and takes no input.
states: running and stopped; the animator runs only while running and visible.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: no role of its own; the surface owning the task announces progress.
size: one `size` square from the icon scale; stroke follows the ring proportion with a one-pixel floor; radius insets half the stroke.
tokens: iconMd, ringStroke, ringDiameter and accent; no local colours or measurements.
motion: infinite rotation on the sweep arc over a faint full ring with round caps; reduced motion lengthens the period.
not designed: fractions, metering a level or labelling; use ProgressBar, Meter or Prose for those.
