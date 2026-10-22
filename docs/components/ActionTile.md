# ActionTile

A stacked icon-over-label tile for equally-weighted session choices laid out as a row, a column or a grid; the host owns selected and armed, and armed outranks selected because what happens next matters more than what is picked.
states: rest, hover, press, focus, disabled, selected and armed; selected is a solid `accent` fill and armed a solid `armedColor` fill, both with `textOnPrimary` glyph and label, `danger` paints the resting glyph and label in `armedColor`, focus rings the body, disabled dims every painted role through Style.disabled rather than composite opacity.
actions: pointer click, Space, Return, Enter, the screen reader's Press action and the `actions` entry call `activate()` and emit `activated`; the tile never changes `selected` or `armed` itself, and a disabled tile activates nothing. `entered` and `exited` report the pointer, so the host moves the selection and disarms.
pointer: the full tile is the target and reports a hand; hover grows the body, a press pulls it in, the wheel does nothing and propagates.
keyboard: Tab reaches each tile in visual order (a click focuses it without a ring, and so does the next press: `focused` defaults to `visualFocus`); Space, Return and Enter read as pressed while held and act once on release, and the repeats of a held key (`isAutoRepeat`) neither press nor act, so one hold can never arm a tile and then confirm it (one 0.7 s hold: 5 activations before the guard, 1 after). Escape is the host's: the unit takes the question back.
screen reader: Accessible.Button named `shownLabel`, so the armed `confirmLabel` is what is announced while armed; `Accessible.selected` follows `selected`.
size: `size` is a Control preset name. The footprint is `Style.tileWidth` by `Style.tileHeight` at md times the preset's share of md, snapped to the 4 px rhythm; the glyph, the label and the gap follow through `iconNear`, `textNear` and `rhythm`, and the label never goes under 12 px. A long label elides inside the tile; content never grows it. `buttonWidth` and `buttonHeight` still set the footprint directly.
tokens: tileWidth, tileHeight, the Control size table, radiusBody, iconLg, the space scale, the surface ladder, accent, danger, text roles, Style.disabled, Motion, StateLayer and Surface; no local colours or measurements.
motion: StateLayer's hover growth and press push-in plus the colour settling in `Motion.micro`; reduced motion shortens the duration and takes the growth to zero.
not designed: what armed means, confirmation policy, asynchronous progress and menus; the host owns them (the library's ArmedAction is the usual arming).

## Contract

- Public: `icon`, `label`, `confirmLabel`, `size`, `selected`, `armed`, `danger`, `accent`, `armedColor`, `buttonWidth`, `buttonHeight`, `focused`, `growthCap`, `activate()`, `entered`, `exited`, `activated`.
- `growthCap`: tiles sit `gap` apart, so a set passes `Motion.hoverGrowthWithin(gap)`; the focus ring follows the growth (`bodyGrows`), and a set with no cap at an 8 px gap has a hovered, focused tile's ring touching its neighbours.
- An empty `label` leaves an icon-only tile with an empty accessible name; a host gives every tile a label.
- Armed and selected differ only in hue when `confirmLabel` is empty (1.04:1 between the two fills); a host that arms gives `confirmLabel`.
- The unit (`workbench/units/ActionTile.qml`) is a session set: Lock, Hibernate, Log out, Restart, Shut down, a full step before the destructive group, with the host owning selection (the pointer and the keyboard focus move it) and arming; it exposes the four sizes, long labels, a selection and disabled. `action-tile-arm` drives hover, click, arm, confirm, disarm on leave, Space and Enter; `action-tile-keyboard` drives click, Escape, Space and Enter and asserts that neither a click nor a key rings a tile.

## Measured at scale 1.25

| size | tile | glyph | label | long label |
| --- | --- | --- | --- | --- |
| xs | 56 x 44 | 16 | 12 | elides |
| sm | 76 x 56 | 20 | 12 | elides |
| md | 96 x 72 | 24 | 12 | elides |
| lg | 116 x 88 | 32 | 14 | elides |

At md, with tiles 8 px apart, hover grows the body 2.4 px per side (the cap; 3.2 uncapped), a press pulls it in, and the focus ring keeps 2.4 px of gap and 2.4 px of stroke around the moving body, 0.8 px clear of each neighbour. The group gap before the destructive tiles is 16 px.

| pair | ratio |
| --- | --- |
| label `textMuted` on `surface` | 6.61:1 |
| glyph `text` on `surface` | 10.53:1 |
| danger label on `surface` | 6.79:1 |
| `textOnPrimary` on selected `accent` | 8.87:1 |
| `textOnPrimary` on armed fill, rendered | 9.21:1 |
| `surface` on the scene ground, rendered | 1.50:1 |

Every size's target is the tile (`drive geom target`: 56 x 44 at xs, 24 px floor passed); the hover zone read from the item tree with a moving pointer is 96 x 72, and tiles in a set keep 8 px between them at rest, 16 px before the destructive group. Focused and hovered, the ring sits 4.8 px outside the grown body (348.8 against 353.6 for the Log out tile) and 0.8 px from the next tile. Tab walks Lock, Hibernate, Log out, Restart, Shut down and the selection follows it.
