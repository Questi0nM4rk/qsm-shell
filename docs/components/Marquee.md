# Marquee

Overflowing text that travels once, always or on hover; at rest it elides like any other line.
states: travelling and resting; travel starts only while the text overflows and the mode wants it, and rest elides on the right; `travelling` and `offset` report whether and how far the text has moved.
actions: none; no signals and no programmatic route; changing the text re-arms a single pass in `once` mode.
pointer: hover mode reads a HoverHandler and claims nothing; other modes ignore the pointer and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: one static text named by the whole `text`, never the visible part; the inner line is ignored so it is not read twice.
size: the host's width clips the line; implicit width is the constant `Style.controlWidth`, never the text's; the height is the line's, a whole number of device pixels; travel distance is the overflow and nothing else.
tokens: the Prose role colour (`muted` forwarded, no colour property) and the Motion durations for dwell, scroll and return; no local colours or measurements.
motion: dwell, scroll and return in sequence, the scroll and the return linear at the reading pace (16 ms a pixel, so 51 px of overflow takes 819 ms; sampled every 50 ms the steps are a constant 3 to 4 px, where the ease-in-out ramped 0.1 to 5.9 px); single pass or infinite by mode; leaving mid-pass returns from the current position; an unknown `mode` logs an error. Measured at 31.6 fps effective, the dwell is one 797 ms gap in the frames (800 asked). Under reduced motion no mode travels and every one rests as an ellipsis, but a hover places the far end of the text, with no travel, and leaving puts it back, so the rest of the line stays reachable.
not designed: wrapping, editing or paced tickers independent of overflow; use Prose or the host for those.
