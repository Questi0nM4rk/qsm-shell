# Marquee

Overflowing text that travels once, always or on hover; at rest it elides like any other line.
states: travelling and resting; travel starts only while the text overflows and the mode wants it, and rest elides on the right.
actions: none; no signals and no programmatic route; changing the text re-arms a single pass in `once` mode.
pointer: hover mode reads a HoverHandler and claims nothing; other modes ignore the pointer and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: the full text is the announcement; travel is visual and never the only channel.
size: the host's width clips the line; implicit size is the text's own; travel distance is the overflow and nothing else.
tokens: text colour and the Motion durations for dwell, scroll and return; no local colours or measurements.
motion: dwell, scroll and return in sequence with the move easing; single pass or infinite by mode; a one-shot position change is removed under reduced motion.
not designed: wrapping, editing or paced tickers independent of overflow; use Prose or the host for those.
