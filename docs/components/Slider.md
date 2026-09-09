# Slider

states: rest hover(thumb grows) press(thumb grows + lifts) focus(keyboard ring) disabled(dims, still reads)
actions: Increase Decrease Minimum Maximum
size: main axis sliderLength / sliderLengthVertical, a constant; cross axis at least controlHeightSm whatever the track thickness is
tokens: sliderStep (the unit every non-pointer route walks in) sliderKeyboardUnits sliderPageUnits sliderLength sliderLengthVertical sliderTrackThickness sliderThumbSize sliderThumbLift space2 (slot gap) controlHeightSm accent surfaceHover text opacityDisabled
motion: fast+standardEasing on the painted position, and ONLY when the change did not come from a gesture; press on the thumb lift; micro on the thumb colour. Reduced motion REMOVES the position animation rather than shortening it, which overrides the library rule in Motion.qml -- a slider's job is to sit where it was put
not designed: ticks, a value tooltip, a range (see the RangeSlider contract in the research), relative drag (Qt's press jumps absolutely, on PRESS)
notes: Accessible.role reads 0 offscreen because QQuickControl sets the attached role only while an accessibility bridge is active; role Slider is asserted by QQuickSlider::accessibleRole() in C++ and the value interface duck-types value/from/to/stepSize off the root
conflicts: none
known: `pressed` is pointer-only here -- Qt's Slider also sets it from the arrows, and the dispatcher takes those before Qt sees them, so the thumb does not lift on a key press; `Keys.onReleased` accepts every key it handles because QQuickSlider::keyReleaseEvent clears `pressed` for ANY key and would otherwise end a pointer drag early; _wheelNotch 120 is a literal in the component and stays one -- it is the platform's wheel unit (eighths of a degree, 15 degrees per notch), not a design value a theme may retune; the a11y increase/decrease route writes value without emitting moved() or committed(), so a host wired only to onMoved never hears a screen-reader change; one arrow press emits valueChanged once per unit (five times) and moved() once; a host that widens from/to must widen stepSize with it, because Home and End walk the range in units; arrows are on-axis only, and Page/Home/End are ours, not Qt parity
audit: docs/audit-2026-09-09-slider.md (Task 5, not yet run)
released: pending owner judgement
