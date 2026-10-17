# Card

A passive surface container for grouping dashboard, performance and theme content; the caller owns its footprint, content and any action inside it.
states: resting surface by default; callers may provide a raised or opaque image-bearing surface through `surfaceColor` and `surfaceOpacity`; `glow: true` (default false) paints the silhouette's granular edge glow inside the card's rounded edge, over the fill and under the content, so a card reads as an object rather than a traced rectangle; hover, press, focus, selected, loading and error belong to an interactive child or the host's content.
actions: none; pointer, keyboard and wheel pass through to children, and Card never claims focus.
screen reader: no role of its own; the meaningful child supplies the accessible name and action.
size: no preset or natural size; the caller's layout and content own both dimensions, while the corner radius remains `Style.radiusLg`.
tokens: `Style.surface`, `Style.surfaceOpacity` and `Style.radiusLg`; with `glow`, `Style.edgeGlow`, `Style.edgeGlowStrength` and `Style.edgeGlowWidth`, the same tokens and grain (`shaders/cardglow.frag`, the 12-mechanism edge-glow formula on a rounded box) as the band; callers may use the surface ladder instead of local colours.
motion: no local motion; a passive grouping surface never implies interactivity.
not designed: an actionable tile, selectable row, dialog, loading shell or error state; use ActionTile, ListRow, Dialog or the content itself.
