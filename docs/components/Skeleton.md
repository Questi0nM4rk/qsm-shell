# Skeleton

A loading placeholder that holds the shape of content still arriving; it reserves space and never carries meaning.
states: line and block. A line occupies the line box of the `Prose` role it stands in for, measured from a real one, and paints a pill one glyph tall inside it; a block occupies the Control preset named by `size` and paints a `radiusSm` body. Stacked lines with no gap are the height of the paragraph that replaces them.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: ignored; a placeholder announces nothing, the surface that is loading says so.
size: width is a fraction of the control width and never content-derived; line height follows its role; block height follows the Control table (`sm`, `md`, `lg`).
tokens: the Control size table, controlWidth, radiusSm, radiusPill, overlay, Prose's role scale; the breath's trough (0.5 of its colour) is a proportion in the file.
motion: an infinite opacity breath on the bar while visible; reduced motion lengthens the 2000 ms period to 4000 ms.
not designed: progress values, error copy or empty explanation; use ProgressBar, Callout or EmptyState for those.

## Measured

Slot at scale 1.25. Line box, placeholder against the text that replaces it (it was the font size, 12 for label, 14 for title): hero 52 / 52, display 33 / 33, heading 26 / 26, title 17 / 17, body 21.7 / 21.7, label and metadata 14 / 14; a four-row card is 85 px loading and loaded (it was 78 loading and 85 loaded). Breath: 61 fps, no gap over 18 ms, one cycle in 2 s (Tailwind and shadcn animate-pulse, https://tailwindcss.com/docs/animation: 2 s, opacity 0.5); the bar goes from 1.62:1 to 1.26:1 against the band (decorative, so exempt).
