# StateLayer

The one owner of the five interaction states; every interactive control forwards rest, hover, press, focus and disabled through it instead of inventing its own. It moves nothing: it reports `growth` and the host applies it to the body it paints.
states: rest, hover, press, focus and disabled via `hovered`, `pressed`, `focused` and `interactive`; hover grows the body by `growth` and the colour lifts through `Style.tone` (or this layer's `hoverTint` disc for a bare glyph); press is a colour change on a body and a push-in only where the host sets `pressScale`.
actions: `activate()` and a real tap share `clicked` on an unhosted, available, clickable layer; a hosted template owns its activation. `hoveredEntered` reports genuine pointer entry while `Interaction.pointerSelects` allows it. `clickable: false` keeps hover feedback and refuses press and click. `manualHoverOverride` and `manualPressOverride` add visual state a host supplies (a key held, a row lit by its open rollout) and never emit intent.
pointer: a pointing hand while interactive and clickable, an arrow otherwise; the wheel is not taken; the hit zone is the layer, which a host sizes to its body at rest.
keyboard: none of its own. `focused` is keyboard focus only: a hosted `T.Control` says it through `visualFocus`, a plain item through its parent's `activeFocus`; a click that takes focus does not ring it until focus is lost and Tab returns.
screen reader: none; the host carries the role, name and state.
size: no footprint; a host sizes the layer to its body at rest. `extent` is the body's smaller side at rest, the number `hoverScale` is a ratio of; `growth` is whole device pixels per side, never under one while the ratio asks for any, never over `growthCap`.
tokens: `Style.stroke` and `Style.snapDown` (the one place the window pixel ratio is read), `Style.indicatorWidth`, `Style.tone`, `Style.focus`, `Motion.hoverScale`, `Motion.press`, `Motion.micro`.
motion: `response` eases to the hover or press scale in `Motion.micro` (`Motion.press` while pressed) and the ring fades in the same time; reduced motion shortens both and takes the hover growth to zero.
not designed: content, layout, dismissal or a keyboard press; a host that wants a held key to read as pressed sets `manualPressOverride`.

## Contract

- The focus ring sits outside the painted body: gap and stroke are each `Style.indicatorWidth` in whole device pixels, the outer radius is the body's plus both, and the ring follows `growth`, so a hovered or pressed body never grows over it.
- `focusColor` carries a stronger semantic state (a failed field's danger) so the ring never erases it.
- The unit (`workbench/units/StateLayer.qml`) is a 190 x 48 surface host: action, trigger (hover feedback, no click) and disabled.

## Measured at scale 1.25

| what | value |
| --- | --- |
| hover growth of a 48 px body | 1.6 px per side (2 device pixels) |
| hover growth of a 72 px body | 3.2 px per side (4 device pixels) |
| ring gap and stroke | 2.4 px each, hovered or not |
| layer size while hovered, unit | 190 x 48, unchanged (the hit zone does not grow with the body) |
| ring rendered, against the scene ground | 10.22:1 |
| ring rendered, against a hovered surface body | 5.20:1 |
