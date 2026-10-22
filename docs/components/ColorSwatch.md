# ColorSwatch

A colour slot: the colour shown as itself, a short reading on it, or an outline when the slot is empty.
states: rest, hover, press, focus, selected and disabled; `empty` shows an outline instead of a face; selected adds an accent ring outside the face, a hairline gap away, so the ring never lies on a neighbour 4 px off; disabled dims each role through `Style.disabled` with the sample's alpha kept, so the check still shows through.
containment: `contained` reports whether the face paints its hairline edge in `textMuted`. A swatch cannot know its ground, so it measures the sample against band, surface and overlay and paints the edge on all three when any is under `Style.contrastGraphic` (3:1), so the same colour looks the same wherever a host puts it; a translucent sample is measured over both cells of the check.
actions: pointer click, Space, Return, keypad Enter, `activate()` and the actions entry emit `clicked`; the host owns selection and what the sample means; a held key does not repeat it.
pointer: the target answers on the `swatchTarget` floor (44 px measured) while the face stays `size`, grows by whole device pixels and is centred on a whole device pixel; wheel does nothing and propagates.
keyboard: tab reaches an enabled swatch, a click focuses without ringing, and a key brings the ring back; `visualFocus` reports it. One ring, concentric with the face, one step outside the selection ring while selected.
screen reader: a checkable Button named by `reading`, else the sample's value, else "Empty colour slot"; the value is the description when a reading names it; `selected` is its checked state; the press action activates.
reading: one line, whole or absent. It is painted only when it fits the face (a clipped "P..." reads as another value), in the ink that measures best on every cell behind the sample, on a band plate when neither ink reaches `Style.contrastText`; the size is `textSm` stepped by `Style.textNear` with the face. The host sizes the face for what it reads.
size: `size` is the painted face; the footprint is `max(size, target)` with the face centred; radius is `radiusSm`; a translucent sample lies on a 5 x 5 check with light corners, so the only curve is the ground's own and no mask is needed.
tokens: swatchTarget, the Control size table, radiusSm, hairline, indicatorWidth, contrastGraphic, contrastText, textSm, checkerLight, checkerDark, surface, text, band, overlay, textMuted, accent and StateLayer; no local colours or measurements.
motion: micro ring fade plus the face swell on hover (at most about one pixel a side, none under reduced motion) and push-in on press.
not designed: a colour picker, palette model or editing; a palette row is one tab stop per swatch (roving focus belongs to a group the host builds).
