# ScrollCue

Non-interactive position furniture for a host `Flickable`: it says there is more past an edge and paints nothing when content fits.

states: fits (nothing), overflowing at the start, in the middle or at the end, on either axis; the mark rests or moves
actions: none; it reports `overflows`, `startFade` and `endFade` and never takes input (`enabled: false`)
pointer: none; the host Flickable keeps the pointer and the wheel
keyboard: none; the host owns focus
screen reader: decorative, no role and no name
size: fills its view; the fade is at most `fadeDepth` (`Style.space6`), a sixth of the viewport, and the content hidden past that edge, so it grows from nothing as the content leaves and is gone at the edge; a side with nothing hidden paints none
tokens: `space5`, `space6`, `spaceTight`, `markThickness`, `textMuted`, `scrollCueRestOpacity`, `scrollCueActiveOpacity`, `fadeColor` (default `surface`)
motion: `Motion.medium` on the mark's opacity only; the fades follow the scroll position and need none
not designed: dragging, ticks, a gauge, or an indicator beside the fade (the mark shows only where `fade` is off)

## Measured

Unit `scroll-cue-short`, a viewport three rows tall (120 px) over 16 rows, at the start / middle / end: start fade 0 / 20 / 20 px,
end fade 20 / 20 / 0 px, so 100 / 80 / 100 px of the viewport stay clear. Fitting content: both fades 0. Full viewport (468 px):
32 px at the far end. The rest mark is 4.04:1 on `band`.

## Open

- The default `fadeColor` is `surface`; most hosts scroll over `band` and state it.
