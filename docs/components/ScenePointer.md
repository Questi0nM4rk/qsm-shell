# ScenePointer

The one hover reader for surfaces; a HoverHandler that belongs on the ancestor of the surfaces so siblings below and above both keep their hover.
states: inside and outside; `inside` is hover now and `position` holds the last reading.
actions: `contains(area)` answers whether the pointer is inside a rectangle or `triangleArea(a, b, c)`; position is never read alone. `inside`, `position` and `contains()` are the pointer contract, so a surface that takes a pointer and a test that supplies one both speak this shape. An optional `source` supplies `inside` and `position` without replacing containment.
pointer: it reads hover and claims nothing; blocking changes neither sibling case, which is why ancestry is the rule.
keyboard: none; it takes no keys and holds no focus.
screen reader: none; it is instrumentation, not content.
size: none; it has no footprint and follows its ancestor.
tokens: none; no Style, Motion or colour roles of its own.
motion: none.
expected: `source: null` reads real hover; an injected `inside`/`position` source uses the same `contains()` implementation. `triangleArea(a, b, c)` and rectangles include their boundary, exclude outside/ghost positions, and reject degenerate triangles. Descendant hover remains independent.
not designed: clicks, gestures or focus; use StateLayer, TapHandler or the host for those.
