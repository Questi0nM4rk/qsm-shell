# Radio

A radio is one option in a host-owned exclusive set; it reports selection intent and never owns group state.
states: rest hover(circle grows 1.15) press(circle shrinks 0.88) focus(ring a half step outside the circle) disabled(every painted role through Style.disabled) off/on
actions: Select (pointer click, Space, Return, `actions[0]` and `select()` share it); disabled or already selected radios refuse; the host answers `selectionRequested()` and owns `checked`
size: `size` resolves through Style.size("Radio", name) into `radioSize` (sm 12 / md 16 / lg 24, escape hatch); the dot is 0.4 of the circle from Caelestia's 8/20 geometry; `sizeScale` = radio / md for host label composition
content: the default slot is adjacent visible content; `accessibleName` is screen-reader-only
colours: off = transparent fill, textMuted ring; on = solid accent fill with textOnPrimary dot; custom `accentColor`; disabled dims each role by colour
base: T.AbstractButton with checkable false, because T.RadioButton owns checked and group behavior belongs outside the component
