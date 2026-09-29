# ScenePointer

The one hover reader for surfaces; a HoverHandler that belongs on the ancestor of the surfaces so siblings below and above both keep their hover.
states: inside and outside; `inside` is hover now and `position` holds the last reading.
actions: `contains(rect)` answers whether the pointer is inside a region; position is never read alone.
pointer: it reads hover and claims nothing; blocking changes neither sibling case, which is why ancestry is the rule.
keyboard: none; it takes no keys and holds no focus.
screen reader: none; it is instrumentation, not content.
size: none; it has no footprint and follows its ancestor.
tokens: none; no Style, Motion or colour roles of its own.
motion: none.
not designed: clicks, gestures or focus; use StateLayer, TapHandler or the host for those.
