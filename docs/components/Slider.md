# Slider

states: rest hover(thumb grows space1 per side; a pill grows along its length only, twice as far) press(growth kept, shadow lift doubles) focus(ring around track and thumb, never around slots or label) disabled(every painted role through Style.disabled, still reads)
actions: Increase Decrease Minimum Maximum
size: sm hairline (space1 track, iconSm thumb), md everyday (iconLg thumb), lg hardware level (controlHeight thumb); md and lg track = thumb minus space1, so a circle is never flush with its track; presets only, thickness/thumbSize stay the API. Main axis sliderLength / sliderLengthVertical plus slots; cross axis at least controlHeightSm and the thumb plus its growth plus the shadow drop
thumb: thumbStyle circle (rides on the track, carries thumbIcon or thumbText) | pill (space1 bar standing space2 proud of the track, in a space1 gap whose cut ends are radiusXs/2, Material stop dot at the far end, carries nothing)
label: labelText and/or labelIcon (metadata role, iconSm) at labelPosition above|below|left|right, whatever the orientation; it takes padding on its side like a slot, outermost, so the track never moves for it. labelClickable makes it the slider's one action surface (StateLayer, hit box at least iconLg, hand cursor) and the host maps the click in onLabelClicked; off, it is a caption and takes no pointer
colours: fill trackColor thumbColor thumbContentColor are the host's; the component never recolours a part for a state
tokens: sliderStep sliderKeyboardUnits sliderPageUnits sliderLength sliderLengthVertical sliderThumbLift space1 space2 iconXs iconSm iconLg controlHeight controlHeightSm accent outline text background textMuted textSm textXs weightBold Style.disabled
motion: fast+standardEasing on the painted position, only when the change did not come from a gesture; micro on thumb growth and colour; press on the shadow lift. Reduced motion removes the position animation and shortens the rest
events: moved(gesture in progress) committed(gesture finished; committedValue is where the last gesture left the value)
not designed: two-thumb range, ticks, wavy fill, value tooltip
