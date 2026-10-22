# Meter

A passive level readout for a quantity with no end (battery, thermal); a progress bar measures a process toward an end and owns indeterminate, a meter owns thresholds and has none. Not a disabled Slider: a slider is input, a meter is output and never offers the pointer a hand.
states: rest(track overlay, fill primary) breached(low/high crossed, fill warning; the reading is unwelcome, not failed; `breached` reports it) disabled(track and fill each through Style.disabled, never opacity, layers stay opaque)
actions: none; no pointer, wheel, keyboard, focus or action API; the host owns value and thresholds
geometry: horizontal fills from the start edge (the right under a mirrored layout), vertical from the bottom, by margins on one fill rectangle so a live orientation change keeps the fill; value clamped 0..1; length alone carries the reading, low/high only tint it; no natural length on the main axis: the host states it
tokens: trackThickness overlay primary warning band Style.disabled
motion: fast+moveEasing on the value (the fraction the fill is drawn from, so a host resize never glides), removed under reduced motion; micro+standardEasing on fill colour; a snapping level reads as jitter
size: fill extent is rounded to whole pixels
screen reader: role Indicator (a level, not a process), named by `accessibleName`; the description is the percentage, with ", low" or ", high" past a threshold
not designed: labels, policy, indeterminate, interactive states; use ProgressBar for a process, Slider for input

## Measured

Slot at scale 1.25: track 4 px (5 device). Vertical, value 0.86, track 380 px: fill 4 x 327 ending on the track bottom (it was 4 x 4 after a live horizontal-to-vertical change). Mirrored: the fill spans x 103 to 430 on a track 50 to 430. Warning fill on track 5.34:1, on band 9.13:1; primary fill on track 5.19:1; track on band 1.71:1 (the ladder's inactive-track role). The warning tint is colour only: a colour-blind reader sees the length, and `breached` is there for a host that adds a second cue.
