# StateLayer

The one owner of the five interaction states; every interactive control forwards rest, hover, press, focus and disabled through it instead of inventing its own. It moves nothing: it reports `growth` and the host applies it to the body it paints.
states: rest, hover, press, focus and disabled via `hovered`, `pressed`, `focused` and `interactive`; hover grows the body by `growth` and the colour lifts through `Style.tone` (or this layer's `hoverTint` disc for a bare glyph); press is a colour change on a body and a push-in only where the host sets `pressScale`.
actions: `activate()` and a real tap share `clicked` on an unhosted, available, clickable layer; a hosted template owns its activation. `hoveredEntered` reports genuine pointer entry while `Interaction.pointerSelects` allows it. `clickable: false` keeps hover feedback and refuses press and click. `manualHoverOverride` and `manualPressOverride` add visual state a host supplies (a key held, a row lit by its open rollout) and never emit intent.
pointer: a pointing hand while interactive and clickable, an arrow otherwise; the wheel is not taken; the hit zone is the layer, which a host sizes to its body at rest.
keyboard: none of its own. `focused` is keyboard focus only: a hosted `T.Control` says it through `visualFocus`, a plain item through its parent's `activeFocus`; a click that takes focus does not ring it until focus is lost and Tab returns.
screen reader: none; the host carries the role, name and state.
size: no footprint; a host sizes the layer to its body at rest. `extent` is the body's smaller side at rest, the number `hoverScale` is a ratio of; `growth` is whole device pixels per side, never under one while the ratio asks for any, never over `growthCap`.
tokens: `Style.stroke` and `Style.snapDown` (the one place the window pixel ratio is read), `Style.indicatorWidth`, `Style.tone`, `Style.focus`, `Motion.hoverScale`, `Motion.press`, `Motion.micro`.
motion: `response` eases to the hover or press scale and the ring fades in `Motion.micro`; reduced motion shortens both and takes the hover growth to zero (the press push-in stays, one device pixel for `Motion.press`).
not designed: content, layout, dismissal or a keyboard press; a host that wants a held key to read as pressed sets `manualPressOverride`.

## Contract

- The focus ring sits outside the painted body: gap and stroke are each `Style.indicatorWidth` in whole device pixels, and the outer radius is the body's plus both.
- `bodyGrows` (default `hoverTint`) says the host applies `growth` to the body this layer rings. The ring then follows it, so a hovered or pressed body never grows over the gap; a host that answers hover with colour alone (a field, a slider, a card) leaves it false and its ring stays put. Hosts that apply `growth` to a body of their own set it.
- `focusColor` carries a stronger semantic state (a failed field's danger) so the ring never erases it.
- `response` eases in `Motion.press` when a press starts and when it ends, and in `Motion.micro` for hover: a Behavior reads its duration before a `pressed ? a : b` binding in it has re-evaluated.
- The unit (`workbench/units/StateLayer.qml`) is a 190 x 48 surface host: action, trigger (hover feedback, no click) and disabled; its flow drives hover, press, Space, Enter and asserts the ring gap at rest, hovered and pressed.

## Measured at scale 1.25

| what | value |
| --- | --- |
| hover growth of a 48 px body | 1.6 px per side (2 device pixels) |
| hover growth of a 72 px body | 3.2 px per side (4 device pixels) |
| ring to body edge, rest, hovered, pressed (IconButton md) | 4.8, 4.8, 4.8 px (before 4.8, 4.0, 5.6) |
| ring to body edge, hovered tile 96 x 72 grown 3.2 px | 4.8 px (before -0.8: the body covered the gap) |
| a focused field hovered, ring outer edge | 205.2 at rest and hovered (unmoved) |
| layer size while hovered, unit | 190 x 48, unchanged (the hit zone does not grow with the body) |
| hover zone from probes | 190 x 48 |
| ring rendered, against the scene ground | 10.22:1 |
| ring rendered, against a hovered surface body | 5.20:1 |
| press push-in, release, hover, to 90 % | 51, 52, 83 ms (tokens 80, 80 as read, 130) |
| reduced motion: hover growth, `Motion.micro`, `Motion.press` | 1 px to 0, 130 to 60, 80 to 40 ms |
