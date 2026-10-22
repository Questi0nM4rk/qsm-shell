# Card

A passive surface container for grouping dashboard, performance and theme content; the caller owns its footprint, content and any action inside it.
states: a resting `surface` by default and always opaque (the shadow is cast by a copy of the body beneath it); `surfaceColor` takes any rung of the surface ladder (`Style.overlay` for a raised card); `glow: true` (default) paints the silhouette's granular edge glow inside the card's rounded edge, over the fill and under the content, so a card reads as an object rather than a traced rectangle; hover, press, focus, selected, loading and error belong to an interactive child or the host's content.
content: Card does not clip its children, because the shadow paints past the bounds; a child with a square fill or image clips itself to the corner (`clip: true` on that child). A control inside takes the rung the other side of the card's (`overlay` on a surface card), or its body is the colour of its ground.
actions: none; pointer, keyboard and wheel pass through to children, and Card never claims focus.
screen reader: no role of its own; the meaningful child supplies the accessible name and action.
size: no preset or natural size; the caller's layout and content own both dimensions, while the corner radius defaults to `Style.radiusBody`. Content sits `Style.space4` in from every edge.
tokens: `Style.surface` and `Style.radiusBody`; with `glow`, `Style.edgeColor`, `Style.edgeStrength` and `Style.edgeFade`, the same tokens and profile (`shaders/cardglow.frag`, the 12-mechanism edge-separation curve on a rounded box) as the band; callers may use the surface ladder instead of local colours.
motion: no local motion; a passive grouping surface never implies interactivity.
measured (rendered, scale 1.25): text 10.53:1 on a surface card and 8.02:1 on an overlay card; content 16 px from all four edges; the body answers no hover (hit map: the card does not respond, its action does, 95 by 32).
not designed: an actionable tile, selectable row, dialog, loading shell or error state; use ActionTile, ListRow, Dialog or the content itself.
