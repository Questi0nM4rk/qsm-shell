# Switch

A boolean that takes effect the moment it is thrown; a checkbox is a statement something else acts on later.
states: rest hover(knob grows space1) press(knob grows space2, never shrinks) focus(ring around the track at a spaceTight gap, concentric) disabled(track and knob through Style.disabled, never opacity) on/off
actions: Toggle (pointer click, Space, Return and `flip()` share it); the host owns `checked` and answers `toggleRequested(checked)`
size: `size` is a preset name resolved by Style.size("Switch", name) into `knobSize` (escape hatch); the rest are proportions: inset an eighth of the knob, track two knobs plus two insets by one knob plus two insets, ring gap spaceTight constant; `sizeScale` = knob / md for a host composing around it. No label inside (a row or Field names it)
tokens: iconSm spaceTight space1 space2 textMuted band accent textOnPrimary radiusPill(track = height / 2)
colours: off = track textMuted, knob band; on = track solid accent (a toggle with its own fill is selected as solid accent), knob textOnPrimary (content on accent is textOnPrimary, as the Checkbox mark)
motion: knob x Motion.fast moveEasing, colours Motion.micro; the knob slides, it is not thrown
events: toggleRequested(bool checked) on every route; nothing else
base: T.AbstractButton with checkable false. Measured: T.Switch writes `checked` itself on a drag release even with checkable false, which takes the state from the host; drag is not offered
not designed: sizes, on/off text (Fluent), icon in the knob (M3), drag
