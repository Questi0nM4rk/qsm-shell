# ActionTile

A stacked icon-over-label tile for equally-weighted session choices laid out as a column or grid; the host owns selected and armed, and armed outranks selected because what happens next matters more than what is picked.
states: rest, hover, press, focus, disabled, selected and armed; armed is danger identity and selected is accent identity over the body, focus rings the body, disabled dims every painted role through Style.disabled rather than composite opacity.
actions: pointer click, Space, Return, Enter and the actions entry call activate() and emit activated; selected and armed never change inside the component and disabled activation does nothing.
pointer: the full tile is the target and reports a hand; wheel does nothing and propagates.
keyboard: Tab reach, click takes focus, and Space/Return/Enter share the activate() route.
screen reader: Accessible.Button named shownLabel, so the armed confirmLabel is what is announced while armed.
size: fixed footprint buttonWidth/buttonHeight from the tile scale so a set lines up; icon, spacing and radius from tokens, content never grows the tile.
tokens: tileWidth, tileHeight, radiusMd, iconLg, space scale, surface ladder, accent, danger, text roles, Style.disabled, Motion, StateLayer and Surface; no local colors or measurements.
motion: StateLayer hover and press response plus color settling; reduced motion shortens the duration, never invents another state.
not designed: confirmation policy, product consequence, asynchronous progress and menus; the host owns what armed means and what activation does.
review: choose a concrete session action with the owner; glyph, verb and confirmation name that same consequence. Power-off is one possible example, not the type's identity. The current fixture is not owner-accepted.
