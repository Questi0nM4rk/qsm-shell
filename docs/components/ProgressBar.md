# ProgressBar

A thin determinate or indeterminate progress line; it shows a fraction or ongoing work and takes no input.
states: determinate fill by clamped value and indeterminate travelling band; disabled blends track and fill opaquely through `Style.disabled`.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: no role of its own; the surface owning the task announces progress.
size: fixed track thickness with pill radius; the indeterminate band is three tenths of the width; the bar fills its host on the main axis.
tokens: trackThickness, accent, outline and disabled colour blending; no local colours or measurements.
motion: fast width settling on value change and a looping sweep while indeterminate and visible; reduced motion lengthens the loop period.
not designed: metering a level, staging steps or labelling; use Meter, Stepper content or Prose for those.
