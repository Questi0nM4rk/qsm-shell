# Capsule

A compact labeled action, selection or status control for panel tabs and popout commands; the host owns active and any in-progress state.
states: rest, hover, press, focus, disabled and active; active is lavender identity over the current surface, primary is a filled `primary` body with `textOnPrimary` content, ghost and destructive show a lifted body under hover and press, focus rings the control body (radiusBody with a label, pill without) for keyboard focus only, disabled dims each painted role through Style.disabled rather than composite opacity.
ground: `base` is the rung the body rests on, `surface` over the band; on a surface card the host passes `Style.overlay`, because a body the colour of its ground is no body.
actions: pointer click, Space, Enter and the actions entry call activate() and emit clicked; the screen reader's press action takes the same route; a held key does not repeat it; active never changes inside the component.
pointer: the full body is the target and reports a hand; wheel does not claim the event; `hovered` and `pressed` report the pointer.
keyboard: tab reaches an enabled capsule, click takes focus without a ring, and Space, Return and Enter read as pressed while held and activate the same route once on release (ActivationKeys).
screen reader: Accessible.Button names the label, or `accessibleName` when glyph-only (a capsule with neither warns once); `checkable: true` marks a toggle and exposes `active` as checked; detail is a muted reading, not a second action.
size: xs, sm, md and lg are the Control presets; the glyph (glyphBeside), label and inset derive from the box, while radius and focus gap remain constant. A glyph-only capsule is the box itself, a circle. The width follows the content up to `controlWidth` and the label elides past it or inside a narrower `width`; a wider `width` keeps the group centred.
tokens: Style.size (Control ladder), glyphBeside, text scale, space scale, surface ladder, accent, danger, Motion, Surface and StateLayer; no local colors or measurements.
motion: subdued capsule hover and press response plus color settling of body and label together; reduced motion shortens the duration, never invents another state.
standing: `T.Control`, not `T.AbstractButton`: the button template owns `icon` as a group property and the glyph here is its name.
measured (rendered, scale 1.25): text on every variant and state 4.5:1 or better, disabled excepted, because the label goes through `Style.legible` against the fill the lift gives it; the hit zone equals the painted body (165 by 32, floor 24); the label sits 0.5 px above the pill's centre and the glyph on it; the hover is 11 real frames 16.5 ms apart (60 fps), 164 ms from first change to rest, the body growing 1 device pixel a side.
not designed: asynchronous progress, confirmation and menu disclosure; callers state progress in label/detail and surfaces own the next layer.
