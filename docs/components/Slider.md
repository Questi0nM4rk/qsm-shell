# Slider

states: rest hover(thumb grows space1 per side, in pixels) press(growth kept, shadow lift doubles) focus(keyboard ring) disabled(every painted role through Style.disabled, still reads)
actions: Increase Decrease Minimum Maximum
size: sm|md|lg presets (sm space1/iconSm, md space2/iconLg, lg space2/controlHeightSm) are only the DEFAULT; thickness/thumbSize stay the primary API. Main axis sliderLength / sliderLengthVertical, a constant, with space1 at each end reserved for hover growth; cross axis at least controlHeightSm and at least thumb plus space1 both sides plus the shadow drop
tokens: sliderStep (the unit every non-pointer route walks in) sliderKeyboardUnits sliderPageUnits sliderLength sliderLengthVertical sliderThumbLift space1 space2 iconSm iconLg controlHeightSm accent surfaceHover text Style.disabled
motion: fast+standardEasing on the painted position, only when the change did not come from a gesture; micro on thumb growth and colour; press on the shadow lift. Reduced motion removes the position animation and shortens the rest
events: moved(gesture in progress) committed(gesture finished; committedValue is where the last gesture left the value, never bound to value)
not designed: ticks, value tooltip, range (RangeSlider), relative drag
open: look to be redesigned against design-system-blueprint.pdf and caelestia StyledSlider; audit lines in docs/BACKLOG.md
