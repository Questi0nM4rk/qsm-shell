# Surface

The Rectangle that binds the state matrix; a component body is one Surface and never its own colour ternary.
states: rest, hover, press, selected, focus and disabled through one `tone` call; selected is accent identity over the layer and content follows it.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none of its own; the hosting control forwards hovered and pressed.
keyboard: none of its own; the hosting control forwards focus.
screen reader: none; the hosting control carries the role and name.
size: none; it fills whatever body hosts it.
tokens: surface, accent, text, disabled and the tone helper; callers pass the base and never local colours.
motion: micro colour settling on state change; reduced motion shortens the duration.
not designed: interaction, feedback or layout; use StateLayer, the control itself or the host for those.
