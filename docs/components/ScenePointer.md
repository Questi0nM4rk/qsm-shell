# ScenePointer

The one hover reader for surfaces: a `HoverHandler` that belongs on the common
ancestor of the surfaces it serves, so a sibling below or above never loses
hover. It reads hover and claims no event, grab or wheel.

## Contract

- `inside` is hover now; `position` holds the last reading, so only
  `contains(area)` answers "is the pointer in this area", never `position` alone.
- `contains(area)` takes `Qt.rect` or `triangleArea(a, b, c)`, includes the
  boundary, answers false while outside, and for a degenerate triangle. Any other
  argument throws `ScenePointerAreaError`.
- `source` (optional) supplies `inside` and `position` from a host or a test and
  keeps the same containment code.
- No keys, focus, role, size, token or motion: it is instrumentation, not content.
  Clicks and gestures belong to `StateLayer`, `TapHandler` or the host.

## Expected

`scene-pointer` shows a card that does nothing but sit in the scene: it has no
hover or press feedback, because it offers no action. With `source: native` the
pointer over the card, over its top-left triangle and over the empty scene each
read as the matching `contains` answer; `injected` answers the same through the
shared implementation.

## Measured

- Native over the card centre: inside, `contains(card)` true, corner triangle
  true; at the card's bottom-right: corner triangle false, card true; over empty
  scene: card false, inside true.
- The fixture card shows the arrow cursor and no tint on hover or press.
