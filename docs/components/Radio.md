# Radio

A radio is one option in a host-owned exclusive set; it reports selection intent and never owns group state.
states: rest hover(circle grows one device pixel a side, colour lifts) press(recolours only, the size holds) focus(keyboard-only ring a half step outside the circle, spaceTight) disabled(every painted role through Style.disabled) off/on
look: off is a 2 px `textMuted` ring, on is a solid `accent` disc with a `textOnPrimary` dot; ring, fill and dot share one clock, so selecting is one cross-fade
actions: Select (pointer click, Space, Return, keypad Enter, the screen reader's press, `actions[0]` and `select()` share it); disabled or already selected radios refuse; the host answers `selectionRequested()` and owns `checked`
size: `size` resolves through Style.size("Radio", name) into `radioSize` (sm 12 / md 16 / lg 24, escape hatch); the dot is 0.4 of the circle rounded to whole pixels (5/6/10), the gap rhythm(circle / 2); `sizeScale` = radio / md and `labelSize` = the type step for a slotted label
content: the default slot is adjacent visible content in a constant `labelWidth` column, so the row is Style.controlWidth x sizeScale wide (380 at md) and a long label elides instead of growing the control (the host binds its label's width to the slot and elides it); the screen-reader name is the slot's first text, `accessibleName` overrides it; an empty slot takes no width and no gap
hit area: the footprint is the target and is at least `Style.targetFloor` tall, the whole row answers
accessibility: role RadioButton, `Accessible.checked` bound; each option is its own Tab stop while enabled, Space and Return select; hand cursor over the row
tokens: radioSize textMuted accent textOnPrimary radiusPill indicatorWidth targetFloor spaceTight
motion: fill, ring and dot Motion.micro; growth through StateLayer (1 under reduced motion)
base: T.AbstractButton with checkable false, because T.RadioButton owns checked and group behaviour belongs outside the component
not designed: arrow-key roving and a single Tab stop for a group (the host owns the group; that needs a group type)
