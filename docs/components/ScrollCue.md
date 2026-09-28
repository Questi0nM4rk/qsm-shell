# ScrollCue

`ScrollCue` is non-interactive position furniture for a host `Flickable`.
It paints nothing when content fits; fades show only beyond the relevant edge.

states: hidden, resting, moving
inputs: `view`, `orientation`, `fade`, `fadeColor`, `indicator`, `fadeDepth`
tokens: `space5`, `space6`, `spaceTight`, `markThickness`, `surface`, `textMuted`
motion: `Motion.medium` mark opacity only
not designed: scrolling input, dragging, ticks, or a gauge
