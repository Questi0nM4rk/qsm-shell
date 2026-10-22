# Sparkline

A small trend line with an optional area fill; it shows shape at a glance and takes no input.
states: none; line or filled area by flag, with explicit minimum and maximum or automatic extents from the values; a flat series centres on a device row; empty is a floor baseline, one point is a dot at the end; values clamp to a pinned extent.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: a graphic with a text equivalent, "Trend, 12 values, from 12 to 61" (also "Trend, no data" and "Trend, one value, 40"); a host whose neighbour already says it sets `Accessible.ignored`.
size: `size` names a preset of the size table (the Control family's, md by default) as the height and the width is three heights (120 x 40 at md; 96 x 32 at sm, 144 x 48 at lg); the stroke defaults to a twelfth of the height in whole device pixels, so a flat run is one crisp row set and not two soft ones (3 crisp device rows at 32 px, where it was 1 soft and 3 full); a stated `thickness` is kept as stated; round caps and joins throughout.
colour: `text` by default, because a trend is a passive reading and the accent has no claim on it (13.71:1 on band); the host passes the series colour it means.
tokens: text, areaFillOpacity and the size table; no local colours or measurements.
motion: none; it repaints on values, colour, area, extents and size.
not designed: axes, labels, interaction or precise readout; use Stat, Prose or the host for those.
