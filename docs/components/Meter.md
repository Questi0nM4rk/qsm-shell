# Meter

A passive level readout for a quantity with no end (battery, thermal); a progress bar measures a process toward an end and owns indeterminate, a meter owns thresholds and has none. Not a disabled Slider: a slider is input, a meter is output and never offers the pointer a hand.
states: rest(track outline, fill accent) breached(low/high crossed, fill warning; the reading is unwelcome, not failed) disabled(track and fill each through Style.disabled, never opacity, layers stay opaque)
actions: none; no pointer, wheel, keyboard, focus or action API; the host owns value and thresholds
geometry: horizontal fills from the start edge, vertical from the bottom; value clamped 0..1; length alone carries the reading, low/high only tint it
tokens: trackThickness outline accent warning background Style.disabled
motion: fast+moveEasing on fill extent, micro+standardEasing on fill colour; a snapping level reads as jitter
screen reader: no role of its own; the host names the reading
not designed: labels, policy, indeterminate, interactive states; use ProgressBar for a process, Slider for input
