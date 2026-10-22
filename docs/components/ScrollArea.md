# ScrollArea

A viewport for static content taller or wider than its room: the content scrolls inside, a sibling `ScrollCue` paints the fades and mark.

states: vertical or horizontal; overflowing or fitting; cues or bare; the region focused by keyboard
actions: `scrollToStart()`, `scrollToEnd()` and `scrollBy(delta)`, clamped to the content so fitting content stays put; the first two are listed in `actions`; `focusRegion()` puts the keyboard on the region; no signals
pointer: the Flickable takes drag and wheel and stops at the edges; a horizontal area also takes the vertical wheel, one notch is a row; chrome never intercepts
keyboard: a tab stop only while it overflows (Tab only, a click does not focus it); Up and Down (Left and Right when horizontal) move a row, PageUp and PageDown a viewport less a row, Home and End the ends; a focused child keeps the keys it handles; the ring is `StateLayer`'s and shows for the keyboard only
screen reader: `Accessible.Pane`, focusable while it overflows; the host names it
size: natural size is `controlWidth` by three `Control` md rows; content never grows it; the host sizes it by layout or anchors
tokens: `Control` md (the line), `controlWidth`, `radiusSm`, and `ScrollCue`'s; fade properties are read through to the cue, which owns their defaults
motion: none of its own; the cue owns fading
not designed: the scrolled content, model delegates or scroll-to-item; a model list is a `ListView` with a `ScrollCue` of its own

## Measured

Unit `scroll-short` (a viewport three rows tall, 120 px): fade 0 / 20 px at the start, 20 / 0 at the end. Hit zone: the viewport rectangle,
which is also the focus ring's body (the ring sits 4 px outside it). Keyboard flow `scroll-area-keyboard` and wheel flow `scroll-area-wheel`
pass offscreen and in a window; Tab order and the accessibility tree were not read (no AT-SPI bus in the slot).
