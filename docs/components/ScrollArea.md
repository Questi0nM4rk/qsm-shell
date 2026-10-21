# ScrollArea

An oriented scroll viewport with overflow furniture; content scrolls inside while a sibling cue paints fades and marks.
states: vertical and horizontal with matching flick direction and content extents; fade, indicator and overflow switch the chrome.
actions: `scrollToStart()` and `scrollToEnd()`, listed in `actions` and clamped to the content, so fitting content stays put; no signals.
pointer: the Flickable takes drag and wheel within bounds and stops at the edges; chrome never intercepts.
keyboard: none of its own; content keeps its own tab stops and keys.
screen reader: no role of its own; content names itself.
size: viewport-sized with no preset; fade depth is twice the large box step; model content uses ListView with a cue directly since Flickable nests none.
tokens: surface, space6 and ScrollCue; no local colours or measurements.
motion: none of its own; the Flickable and the cue own movement and fading.
not designed: the scrolled content, model delegates or scroll-to behaviour; use the host with ListView or a Flickable child for those.

## UIX audit

Evidence: source-reviewed only. No runtime exercise, no tree read, no owner acceptance. The fades
and the position mark are painted by `ScrollCue`, whose own record is not part of this audit; its
defects are listed here because `ScrollArea` composes it and owns the motion the viewer sees.

### Purpose and consequence

A viewport for static content taller or wider than its room. The task it finishes: the person can
reach content that does not fit, and can see that more exists in the scroll direction. Failure
means rows are cut with nothing saying so, or content cannot be reached at all.

### Controls, states and what is implemented

| Expected | Where | State |
| --- | --- | --- |
| `orientation` (vertical, horizontal) | `ScrollArea.qml:25`, read at `:36` | implemented; any value other than `Qt.Vertical` is horizontal |
| `fade`, `indicator`, `fadeColor`, `fadeDepth` | `ScrollArea.qml:26-29`, passed to `ScrollCue` at `:57-65` | implemented |
| `viewport` and `overflows` read-outs | `ScrollArea.qml:33-34` | implemented |
| actions to start, to end | `scrollToStart()`, `scrollToEnd()` and `actions` in `ScrollArea.qml`; the unit's `settle` stays a viewport call | implemented, SA-2 fixed |
| vertical, horizontal, overflowing, fitting, cues, bare | `workbench/units/ScrollArea.qml:44-57` | the unit exposes all combinations |

Fitting content shows neither fade nor mark (`ScrollCue.qml:71`, `:104`, `:117`).

### Routes

- Pointer: drag and wheel on the Flickable (`ScrollArea.qml:38`), stopping at the bounds
  (`:46`, no overshoot). The cue is disabled (`ScrollCue.qml:61`), so the mark has no pointer route.
- Wheel: the native Flickable. Whether a vertical wheel scrolls a horizontal viewport is H-2.
- Keyboard: none. The Flickable takes no focus and handles no key (`ScrollArea.qml:38-55`). SA-1.
- Focus: no ring, because the viewport is never focused.
- Screen reader: no role or name on the viewport (H-4).

### Sizes, empty and long content, failure

- No implicit size is declared (`ScrollArea.qml`, top item, lines 18-66). Documented as
  viewport-sized, see C-2 and P-1.
- Fade depth is `Style.space6 * 2`, 64 px at md (`ScrollCue.qml:39`).
- Mark: 3 px thick (`markThickness`, `tokens/deep-night.json:106`), length clamped to
  `Style.space5` (24 px) through `Style.space6 * 2` (64 px) (`ScrollCue.qml:66-67`), inset
  `Style.spaceTight` (2 px, `Tokens.qml:27`).
- Empty content: `childrenRect` is zero. Not examined.
- Long single-line content in a horizontal viewport: not examined.
- Failure and cancellation: none defined. A drag can be cancelled by the Flickable itself only.

### Visual roles and palette pairs

- Fades paint `fadeColor`, default `Style.surface` (`ScrollCue.qml:33`). Opaque to 30 percent of
  the depth, then transparent (`:107-109`); the bottom fade is opaque from 70 percent (`:120-122`).
- Mark: `Style.textMuted`, opacity `Style.scrollCueActiveOpacity` (0.8) while moving, else
  `Style.scrollCueRestOpacity` (0.6) (`tokens/deep-night.json`).
- Contrast of the mark and of the fade against the consumer's ground: not computed.

### Motion and reduced motion

- Mark opacity: `Behavior` with `Motion.medium` (260 ms, `tokens/deep-night.json:57`) and
  `Motion.standardEasing` (`Easing.OutCubic`, `Motion.qml:120`), `ScrollCue.qml:83-85`. Reduced
  motion shortens the duration to 100 ms and keeps the opacity change (`Motion.qml:58`).
- Fades: no transition at all. The `visible` bindings flip in one frame (SA-2).
- Movement: the native Flickable flick and bounds. Nothing in this component animates it.
- review-animations, source only: standard 1 holds for the mark; standard 2 is open for the mark's
  fade on every flick (C-3); standard 4 holds (260 ms, under 300); standard 5 holds (no scale);
  standard 7 holds (opacity only); standard 8 holds (`Motion.qml:58`); standards 3, 6, 9 and 10 do
  not apply to this surface. Verdict: not approved, because SA-2 is a jarring change.

### Pointer geometry

- Input shape: the Flickable rectangle, `anchors.fill: parent` (`ScrollArea.qml:41`), clipped. The
  painted size is the same rectangle, so input and paint match.
- Chrome input shape: none. The cue is disabled (`ScrollCue.qml:61`), so the mark and fades take
  no pointer.
- Story viewport: 800 by 500 (`workbench/stories.json`), less the `Style.space4` margin (16 px) on
  each side, which gives 768 by 468 (assumption: the story viewport as given).
- Row step: Control `md` (40 px, `tokens/deep-night.json`). Sixteen rows give 640 px of
  content, so the visible ratio is 468 / 640 = 0.73, and the mark is at its 64 px cap.
- No task that the component offers has a target. The mark has zero hit area. ID is not defined.
- Worked consumer case (assumed values, not a human average): a pointer lands on a row at the far
  edge of the viewport. D = 468 px (the viewport height, assumed aim distance). W = 40 px (the row
  step, assumed line box), one-dimensional along the scroll axis. Landing tolerance W / 2 = 20 px.
  ID = log2(1 + 468 / 40) = log2(12.7) = 3.67 bits. Label origin: none assumed, the row text is the
  target. Weight: not applicable.
- Neighbouring interference: the mark is 3 px wide, 2 px inside the right edge, over the rightmost
  5 px of content when content reaches that edge (`ScrollCue.qml:72`). Rows are 40 px apart, so
  the mark never crosses a row boundary.
- Popup corridor and timing: not applicable, this is not a popup.

### Findings

Defects, each cited to a line and to the person's experience:

- **SA-1**, major, `qml/QsmShell/Components/ScrollArea.qml:38-46`, shared: true (the focus ring
  belongs to `StateLayer.qml` by law). A person who tabs to a list of static text, or to any
  overflowing region without focusable children, cannot focus it and cannot scroll it with the
  keyboard. Lines 38-55 contain no `activeFocusOnTab`, no key handler and no Accessible property.
  The unit rows are `Prose` and not focusable (`workbench/units/ScrollArea.qml:27-41`). Cites
  WCAG 2.1.1; the a11y-audit conformance row is not run. Fix: the viewport takes focus when it
  overflows, Up, Down, PageUp, PageDown, Home and End call one scroll function (`scrollToStart()` and `scrollToEnd()` exist), and the ring
  comes from `StateLayer`.
- **SA-2**, minor, needs a change in `ScrollCue.qml` (opacity `Behavior` on both fades), `qml/QsmShell/Components/ScrollCue.qml:104` and `:117`, shared: false. The
  fades switch on and off in one frame, with no `Behavior`. On the first pixel of scroll an opaque
  strip of 0.3 x 64 = 19 px appears over the content, and it disappears in one frame at the end.
  Compare the mark, which has a `Behavior` (`:83`). Fix: give both fades an opacity `Behavior` from
  a `Motion` token, or record the snap as deliberate under P-5.

Proposals (taste and owner decisions, not defects):

- **P-1**: give `ScrollArea` a natural size from the `Style` size table, such as the unit's
  `controlWidth` and Control `md`, so a Layout child does not collapse to 0; or record the zero
  as deliberate. Owner decision, see C-2.
- **P-2**: change the default `fadeColor` to `Style.band`, the ground most hosts scroll over, or
  make the consumer state it. The surface default is right for a card and wrong for a band.
- **P-3**: a pointer route to the position. Caelestia's `StyledScrollBar.qml` has a draggable thumb
  that is 0 at rest, 0.6 while moving and 0.8 on hover, and a 600 ms hide delay (`Timer`
  `interval: 600`). `ScrollCue.qml:20-22` declares the cue not draggable, and that is the owner's
  call. The trade-off is a hit area taken from the rows underneath. The rest opacity also differs:
  0.2 here against 0 in caelestia.
- **P-4**: the mark is painted over the content with no gutter (`ScrollCue.qml:72`). Overlay
  scrollbars are common; state it as a choice, not a defect.
- **P-5**: the mark's fade on every flick (`ScrollCue.qml:83`) is an animation on an action that
  happens many times a day (C-3). Either remove the `Behavior` and snap, or keep it as a deliberate
  exception; SA-2 needs the same decision for the fades.

Source conflicts, recorded and not resolved here:

- **C-1**: this record's line 9 says "viewport-sized with no preset". AGENTS requires a natural size
  that is a constant (definition of done, item 5). The two cannot both hold.
- **C-3**: review-animations standard 2 gives no animation to actions of 100 or more a day. The
  cue's own comment (`ScrollCue.qml:80-82`) justifies the mark's motion during scroll.

Hypotheses (unmeasured, not in the table):

- **H-2**: a vertical wheel over a horizontal viewport (`ScrollArea.qml:43`) may not scroll it. Qt's
  wheel mapping is not checked here.
- **H-3**: a programmatic jump does not set `view.moving` (`ScrollCue.qml:80`), so the mark stays at
  rest opacity while the view jumps.
- **H-4**: the viewport has no Accessible role or name, so a screen reader may announce no scroll
  region. Needs the accessibility tree.


Caelestia comparison: `StyledScrollBar.qml` is a sibling control, not an equivalent. It is
interactive and hides after a delay, where this cue is not interactive and dims at once.

### Not examined

- Any runtime behaviour: wheel, drag, keyboard, focus, the accessibility tree, text scale 200 percent.
- Empty content, long horizontal text, a Layout placement, the Qt version's `childrenRect` semantics.
- Contrast of the fade and the mark against the actual ground (colour values not read).
- Reduced motion on a live surface.
