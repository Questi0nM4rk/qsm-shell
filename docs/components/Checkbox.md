# Checkbox

A boolean that is a STATEMENT, not an action: something else acts on it later; if throwing it takes effect immediately, it is a Switch.
states: rest hover(box grows one device pixel a side, colour lifts) press(colour deepens, the size holds) focus(keyboard-only ring a half step outside the box, radiusXs, box only) disabled(every role through Style.disabled, never opacity) off/on/indeterminate(some but not all, outranks checked)
look: off is a 2 px `textMuted` outline, on is solid `accent` with a `textOnPrimary` check, indeterminate is solid accent with a dash a whole number of device pixels thick (the check's stroke weight and width, so "some" weighs what "yes" does); the ring stays and takes the fill's colour, so checking is one cross-fade
actions: Toggle (pointer click, Space, Return, keypad Enter, the screen reader's press and toggle, and `flip()` share it); the host owns `checked` and `indeterminate` and answers `toggleRequested(checked)`; a mixed box reports checked false, so what clicking "some" means is the host's answer
accessibility: role CheckBox; indeterminate reports the mixed state, not checked; Tab stop while enabled; hand cursor over the row; the host names the instance (`accessibleName`)
size: `size` is a preset name resolved by Style.size("Checkbox", name) into `boxSize` (sm 12 / md 16 / lg 24, escape hatch); the mark is 3:4 of the box, the row gap rhythm(box / 2), radiusXs, the 2 px outline and the ring gap constant; `sizeScale` = box / md and `labelSize` = the type step for a slotted label
content: the default slot is an adjacent label (or anything), clipped in a constant `labelWidth` column, so the row is Style.controlWidth x sizeScale wide (380 at md) and a long label elides instead of growing the control; the host binds its label's width to the slot, elides it and colours it for disabled; the component never renders its own label
hit area: the footprint is the target and is at least `Style.iconLg` tall, the whole row answers; natural size is box and label centred in that height
tokens: boxSize textMuted accent textOnPrimary radiusXs indicatorWidth iconLg spaceTight
motion: fill and ring Motion.micro; box growth through StateLayer (1 under reduced motion)
events: toggleRequested(bool checked) on every route; nothing else
base: T.AbstractButton with checkable false. Measured: a template checkbox writes `checked` itself on click and a tristate one cycles all three states
not designed: a tri-state cycle, drag
