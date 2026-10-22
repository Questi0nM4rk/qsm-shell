# Prose

The one type scale; ten roles from hero to section with muted and technical axes, and body is the only role that wraps.
states: none; roles, muted and technical are static facts, never interaction states.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: plain text always; single roles elide and body wraps; section renders uppercase with wide tracking as a label, not a shout.
size: pixel sizes from the text scale (none under 12) and weights from the weight scale; line height belongs to wrapping body only; technical roles use the technical face without kerning. The text box is a whole number of device pixels tall: the slack under one device pixel is `bottomPadding`, never `lineHeight`, which would move the glyphs, and the height is also the layout's preferred height because a layout rounds an implicit one up. Inside a Layout positions are whole logical pixels (Qt), so stacking on the device grid at 1.25 there needs heights on the 4 px rhythm.
roles: `supporting` and `metadata` render alike (muted, regular, 12); the name says which of the two a call site means.

| role | px | weight | colour | line height | face |
| --- | --- | --- | --- | --- | --- |
| hero | 44 | DemiBold | text | 1 | sans |
| display | 28 | DemiBold | text | 1 | sans |
| heading | 22 | DemiBold | text | 1 | sans |
| title | 14 | DemiBold | text | 1 | sans |
| body | 12 | Regular | text | 1.55, wraps | sans |
| label | 12 | Medium | text | 1 | sans |
| supporting, metadata | 12 | Regular | textMuted | 1 | sans |
| reading | 12 | DemiBold | text | 1 | monospace |
| section | 12 | DemiBold | textMuted | 1, uppercase, tracked | sans |

contrast: text on band, surface, overlay 13.71, 10.53, 8.02; textMuted 8.61, 6.61, 5.04 (4.5 holds on all three).
tokens: the text, weight, line and tracking scales plus text and textMuted; no local colours or measurements.
motion: none.
not designed: input, labelling controls or truncation policy beyond elision; use TextField, ControlLabel, Field or the host for those.
