# Checkbox

A boolean that is a STATEMENT, not an action: something else acts on it later; if throwing it takes effect immediately, it is a Switch.
states: rest hover(box grows 1.15) press(box shrinks 0.88) focus(ring a half step outside the box, radiusXs, box only) disabled(every role through Style.disabled, never opacity) off/on/indeterminate(some but not all, outranks checked)
actions: Toggle (pointer click, Space, Return and `flip()` share it); the host owns `checked` and `indeterminate` and answers `toggleRequested(checked)`
screen reader: indeterminate reports the mixed state, not checked; press and toggle actions share `flip()` and respect disabled without writing host state.
size: `size` is a preset name resolved by Style.size("Checkbox", name) into `boxSize` (sm 12 / md 16 / lg 24, escape hatch); the mark scales WITH the box (check at 3:4, dash at half), the row gap through rhythm(box/2); radiusXs, the 1px border and the ring gap constant; `sizeScale` = box / md for a host composing around it
content: the default slot is an adjacent label (or anything); the component never renders its own label; the host colours it for disabled
tokens: boxSize outline accent background radiusXs spaceTight
colours: off = transparent fill, outline border; on = solid accent fill, background mark (a toggle with its own fill is selected as solid accent); indeterminate = accent fill, background dash; disabled = every role through Style.disabled
motion: fill Motion.micro; box growth/press through StateLayer
events: toggleRequested(bool checked) on every route; nothing else
base: T.AbstractButton with checkable false. Measured: a template checkbox writes `checked` itself on click and a tristate one cycles all three states; Space is the template's click, Return and the pointer route call `flip()`
not designed: a tri-state cycle (the host decides what clicking "some" means), drag
