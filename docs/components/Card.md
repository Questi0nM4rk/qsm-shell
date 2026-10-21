# Card

A passive surface container for grouping dashboard, performance and theme content; the caller owns its footprint, content and any action inside it.
states: a resting `surface` by default and always opaque (the shadow is cast by a copy of the body beneath it); `surfaceColor` takes any rung of the surface ladder (`Style.overlay` for a raised card); `glow: true` (default) paints the silhouette's granular edge glow inside the card's rounded edge, over the fill and under the content, so a card reads as an object rather than a traced rectangle; hover, press, focus, selected, loading and error belong to an interactive child or the host's content.
content: Card does not clip its children, because the shadow paints past the bounds; a child with a square fill or image clips itself to the corner (`clip: true` on that child).
actions: none; pointer, keyboard and wheel pass through to children, and Card never claims focus.
screen reader: no role of its own; the meaningful child supplies the accessible name and action.
size: no preset or natural size; the caller's layout and content own both dimensions, while the corner radius defaults to `Style.radiusBody`.
tokens: `Style.surface` and `Style.radiusBody`; with `glow`, `Style.edgeColor`, `Style.edgeStrength` and `Style.edgeFade`, the same tokens and profile (`shaders/cardglow.frag`, the 12-mechanism edge-separation curve on a rounded box) as the band; callers may use the surface ladder instead of local colours.
motion: no local motion; a passive grouping surface never implies interactivity.
not designed: an actionable tile, selectable row, dialog, loading shell or error state; use ActionTile, ListRow, Dialog or the content itself.

## UIX audit

D4 is open: callers clip their own content; routing children into a clipping content item is an API
change awaiting the owner.

Method: source-reviewed only. No capture, no live geometry, no Workbench session. Evidence channel
available: source files and the design tokens (`qml/QsmShell/Style/Tokens.qml`). Ratios below are
WCAG 2.x relative-luminance ratios computed from token hex values, not from rendered pixels.

### Purpose and consequence

Card is the passive grouping surface: it finishes the job of putting related content on one
silhouette that reads as an object. The consequence of a wrong Card is that a group reads as loose
text on the band, or that a card sits on the wrong rung of the ladder.

### Expected controls and states

| Control | Declared at | Implemented | Note |
| --- | --- | --- | --- |
| `surfaceColor` | Card.qml:9 | yes | default `Style.surface` |
| `glow` | Card.qml:15 | yes | default true |
| `shadow` | Card.qml:18 | yes | default true |
| `radius` | Card.qml:21 (Rectangle) | yes, overridable | default `Style.radiusBody` |
| children | default property | yes | caller owns content and footprint |

Valid states as the unit exposes them: resting (default) and raised, glow on and off, shadow on and
off.

### Routes

- Pointer: none. Card declares no pointer handler, no `hoverEnabled`, no `MouseArea`; a Rectangle
  without them does not accept the pointer, so presses, hover and wheel pass to whatever lies
  beneath (Card.qml has no such declarations, checked by grep).
- Keyboard and focus: none. Card sets no `activeFocusOnTab` and claims no focus. A host may still
  assign `focus: true` on an instance (Dialog.qml:127), which is the host's act.
- Screen reader: none. Card.qml has no `Accessible.*` property. Children are exposed as a flat
  sequence; whether the tree shows that is not tested (Hypotheses H2).
- Failure and cancellation: none. A failed or loading state belongs to the host, as the record says.

### Sizes, empty and long content

- Sizes: no preset and no natural size. Card.qml declares no `implicitWidth` or `implicitHeight`, so
  a Card with no caller size is 0 by 0. Callers size it (Dialog.qml:123-124 sets width and implicit
  height).
- Empty content: a plain surface slab with its shadow and edge line.
- Long content: Card.qml has no `clip`. Children paint past the rounded silhouette (D4).

### Visual roles and palette pairs

Token values from Tokens.qml, computed here:

| Pair | Ratio | Source | Verdict |
| --- | --- | --- | --- |
| `Style.text` #f0ecf5 on `surface` #3b3145 | 10.53:1 | Tokens.qml:9, 7 | passes 4.5 for body text |
| `Style.textMuted` #c5bad1 on `surface` | 6.61:1 | Tokens.qml:10, 7 | passes 4.5 |
| `surface` on `band` #271e30 | 1.30:1 | Tokens.qml:6-7 | the ladder's step |
| `Style.edgeColor` #5e357f on `surface` | 1.19:1 | Tokens.qml:20 | decorative separation, not a fact-bearing border, so no 1.4.11 duty applies |

The edge is the silhouette's separation (AGENTS.md "Surface ladder and borders"); it carries no
meaning colour alone would hide. The shader curve matches docs/12-mechanism.md "Edge separation":
`w = edgeColor.a * (1 - s)^2` with `s = clamp(dist / edgeFade)` (cardglow.frag:42-43 against the
mechanism's `w`). The card needs no gradient normalisation, because a box SDF is already a true
distance (cardglow.frag:9-10).

### Motion and reduced motion

- Card animates nothing: no `Behavior`, `Animation` or transition in Card.qml. review-animations was
  not run for this record. Hosts animate: Dialog binds `opacity` and `scale` to its open state
  (Dialog.qml:128-129); Capsule animates its own `surfaceColor` and body opacity,
  which reach Card through its binding.
- Reduced effects: with `Style.reducedEffects`, the shadow layer is not created (Card.qml:32). The
  edge glow still paints, since it is a static shader (Card.qml:48). The docs do not state what
  reduced effects must remove (H1).

### Pointer geometry

- Input shape: none. Card is not hit-tested for input, so the input shape is empty.
- Painted size: the caller's `width` by `height` at radius `Style.radiusBody` = 12.
  The shadow paints up to `cardShadowExtent` = 12 px past the edge with a 2 px downward offset
  (Tokens.qml:121-122, Card.qml:33-39). Visual only; not input.
- D, W, ID: not applicable. Card is passive and has no target. A caller's target inside a Card
  carries its own geometry and belongs in that type's record.
- Corridor and timing: not applicable. Card opens nothing.
- Label origin and weight assumptions: not applicable.

### Findings

Source-backed defects (each line cites the file, the line, and what a person sees):

- **D4 (minor), no clip on content.** Card.qml declares no `clip`, so a child with its own square
  fill or image paints across the rounded corner and past the card's bounds; a host clips that child
  itself (`clip: true` on it). Fix: do not
  set `clip: true` on Card itself: the shadow layer (Card.qml:26-39) extends past the bounds and
  the clip would cut it. A correct fix clips only the caller's content, which changes the child
  API (a content item). Shared: no.

Redesign proposals (taste, not defects):

- Expose the card's role to assistive tech with a grouping role and a name taken from its title,
  so a screen reader announces the group. This adds API; it needs the owner's ruling.
- Caelestia has no Card. Its nearest siblings are `components/StyledRect.qml` (a Rectangle whose
  colour animates through CAnim) and `components/StyledClippingRect.qml` (the clipping variant).
  Neither has a shadow or an edge shader. The shadow and edge are this library's divergence and
  are deliberate under Quiet Luminous; keep them and say so in the record.
- Card has no implicit size, so a Card placed in a Layout with no preferred size collapses to zero.
  A constant natural size, or a note in the record that callers must set one, removes the trap.

Hypotheses (observed in source, not run):

- H1: the reduced-effects contract is undefined in the docs (a search of docs/*.md finds nothing);
  the current behaviour drops only the shadow.
- H2: the accessibility tree shows Card's children as a flat list with no grouping. Not tested;
  a11y-audit owns it.

### Evidence

- Source-reviewed: every row above, from the files and lines cited, plus the token arithmetic.
- Runtime-exercised: none. No capture, no tree, no session was run.
- Owner-accepted: none.

### Not examined

- Light theme and any other theme: only the deep-night token set is in Tokens.qml, and the
  backend overrides are not read.
- Rendered output: the z-order claim (the shadow copy paints beneath the fill) is the documented Qt
  behaviour for negative `z` and has not been seen on screen.
- Prose text colour inside a Card: the card's text roles were not traced through Prose.
- The shader's compiled `.qsb` against `cardglow.frag`: drift was not checked, because the test
  suite is not run without an explicit request.
- Host behaviour of Dialog, Capsule, Callout and Popover beyond their Card usage lines.
