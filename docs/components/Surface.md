# Surface

The Rectangle that binds the state matrix; a component body is one Surface and never its own colour ternary.
states: rest, hover, press, selected and disabled through one `tone` call (focus is the ring `StateLayer` paints, never a Surface state); selected is accent identity over the layer and content follows it.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none of its own; the hosting control forwards hovered and pressed.
keyboard: none of its own; the ring is `StateLayer`'s.
screen reader: none; the hosting control carries the role and name.
size: none; it fills whatever body hosts it. `radius` defaults to `Style.radiusBody`, so a bare Surface is a finished rounded body; a caller states its own corner, and `snapEdge` squares the two corners on one wall (an unknown value is reported on the error stream).
tokens: surface, accent, text, disabled and the tone helper; callers pass the base and never local colours.
motion: micro colour settling on state change; reduced motion shortens the duration.
not designed: interaction, feedback or layout; use StateLayer, the control itself or the host for those.
measured (rendered, 1.25 scale): text on rest 10.53:1, on hover 8.03:1, on press 6.56:1, accent text on selected 5.25:1; disabled text 2.65:1 (inactive); the label centres on the body within 0.5 px; the host's hit layer is exactly the painted body (190 by 40, floor 24).
