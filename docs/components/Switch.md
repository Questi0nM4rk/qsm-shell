# Switch

A boolean that takes effect the moment it is thrown; a checkbox is a statement something else acts on later.
states: rest hover(knob grows one device pixel a side, colour lifts) press(colour deepens, the knob keeps its grown size) focus(keyboard-only ring, concentric around the track at a spaceTight gap) disabled(every role through Style.disabled, never opacity) off/on
look: off is a 2 px `textMuted` outline with a `textMuted` knob, on is a solid `accent` track with a `textOnPrimary` knob; ring and fill share one colour, so throwing it is one cross-fade, and the pair matches Checkbox and Radio (an empty toggle is an outline, a selected one is filled accent)
actions: Toggle (pointer click, Space, Return, keypad Enter, the screen reader's press and toggle, and `flip()` share it); the host owns `checked` and answers `toggleRequested(checked)`; the host names the instance (`Accessible.name`), the component has no label
size: `size` is a preset name resolved by Style.size("Switch", name) into `knobSize` (sm 12 / md 16 / lg 24, escape hatch); the track is two knobs wide and one knob tall plus 4 px of air on every side (32x20, 40x24, 56x32); the footprint is the pointer target and is at least `Style.iconLg` tall, so the sm track centres in 24; `sizeScale` = knob / md. No label inside (a row or Field names it)
tokens: spaceTight space1 iconLg indicatorWidth textMuted accent textOnPrimary radiusPill
motion: knob x Motion.fast moveEasing (not played under reduced motion), colours Motion.micro; hover growth is 1 under reduced motion
accessibility: role Switch, `Accessible.checked` bound to `checked`; Tab stop while enabled; hand cursor over the footprint
events: toggleRequested(bool checked) on every route; nothing else
base: T.AbstractButton with checkable false. Measured: T.Switch writes `checked` itself on a drag release even with checkable false, which takes the state from the host; drag is not offered
not designed: on/off text (Fluent), icon in the knob (M3), drag, a pending state
