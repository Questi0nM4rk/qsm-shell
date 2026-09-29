# StatRing

A passive output: one fraction bent into a circle, with its reading held in the middle. A bar compares against other bars; a ring reads as one quantity at a glance.
states: none interactive. Rest is the only state; there is no hover, press, focus, selected or disabled. Value clamps to 0..1 and a fraction at or below 0.005 paints no fill arc, so zero reads as none rather than a round-capped dot.
pointer: claims nothing. No MouseArea, HoverHandler, WheelHandler, Keys handler or focus policy; wheel and keyboard pass through to whatever lies beneath.
screen reader: Accessible.StaticText names "label, reading" as one readout (whichever half is set when only one is).
size: natural size is the diameter square; diameter defaults to Style.ringDiameter, stroke to Style.ringStroke, the reading to Style.textXl. A caller that needs another size states diameter and readingSize; the icon follows the reading size, capped to the content box.
content: icon, reading and label stack centred in a column no wider than the ring box (diameter minus stroke and rhythm); long reading/label text elides on one line and never enlarges or overflows the component. Formatting is the caller's: "72%" and "3.4 GB" are the same ring.
shape: startAngle/sweepAngle make the form. Open (-225/270, gap at the bottom) holds its label inside the circle; closed (-90/360) is the full ring Avatar draws its progress on.
tokens: accent fill, outline track, text icon, Prose reading/metadata roles; no local colors or measurements.
motion: none. Data, color, angle and geometry changes repaint the Canvas in the same frame; a one-shot position animation would move a number away from where it was put.
not designed: thresholds (Meter owns them), indeterminate progress (ProgressBar), interaction, dismissal or selection; the host owns the value and never the ring.
