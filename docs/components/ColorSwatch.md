# ColorSwatch

A colour sample with a readable value text; the ink over the sample is picked by measured contrast, never by assumption.
states: rest, hover, press, focus, selected and disabled; `empty` shows an outline over a check field instead of a face; selected adds a ring; disabled dims by colour, never composite opacity.
actions: pointer click, Space, Return and the actions entry emit `clicked`; the host owns selection and what the sample means.
pointer: the full swatch is the target with a StateLayer swell; wheel does nothing and propagates.
keyboard: tab reaches an enabled swatch, click takes focus, and Space and Return share the click route.
screen reader: the `reading` names the sample; ink is chosen against both check cells so the text reads on any ground.
size: one `size` square from the control-height scale; radius is `radiusSm`; the ring overflows the face instead of growing it.
tokens: controlHeight, radiusSm, markThickness, textXs, surface, text, background, outline, accent, opacityDisabled and StateLayer; no local colours or measurements.
motion: micro ring response plus StateLayer hover and press swell; reduced motion shortens the duration.
not designed: a colour picker, palette model or editing; it shows one sample and reports the click.
