# ColorSwatch

A colour sample with a readable value text; the ink over the sample is picked by measured contrast, never by assumption.
states: rest, hover, press, focus, selected and disabled; `empty` shows an outline instead of a face; selected adds an ink ring on the face; disabled dims each role through `Style.disabled` with the sample's alpha kept, so the check still shows through.
actions: pointer click, Space, Return, `activate()` and the actions entry emit `clicked`; the host owns selection and what the sample means.
pointer: the target answers on the `swatchTarget` floor while the face stays `size` and swells in place; wheel does nothing and propagates.
keyboard: tab reaches an enabled swatch, click takes focus, and Space and Return share the `activate()` route.
screen reader: a Button whose `reading` names the sample; ink is chosen against both check cells so the text reads on any ground.
size: `size` is the painted face; the layout footprint is `max(size, swatchTarget)` with the face centred, so 24px palette samples keep 24px faces on 44px targets; reading has a `spaceTight` inset and elides before the edge; radius is `radiusSm`; rings hug the face instead of the target.
tokens: swatchTarget, controlHeight, radiusSm, spaceTight, markThickness, textXs, surface, text, background, outline, accent and StateLayer; no local colours or measurements.
motion: micro ring response plus StateLayer face swell on hover and press; reduced motion shortens the duration.
not designed: a colour picker, palette model or editing; it shows one sample and reports the click.
