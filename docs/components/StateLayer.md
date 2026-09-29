# StateLayer

The component that owns the five states; every interactive control forwards rest, hover, press, focus and disabled through it instead of inventing its own.
states: rest, hover, press, focus and disabled via hovered, pressed, focused and interactive; the response swells on hover and shrinks on press, and focus draws a one-pixel accent ring.
actions: `clicked` and `hoveredEntered` report intent; `clickable: false` keeps hover feedback for a rollout trigger while refusing press and click. It hosts a target or parents itself, and growth lands on the target while the layer never grows a layout.
asserted state: `manualHoverOverride` and `manualPressOverride` let an external owner assert a state INTO the layer, from caelestia's `StateLayer`. "This entry is open, therefore lit" costs two booleans here and cost the rail 130 lines of geometric union. A host that must re-implement something to keep a layer lit has found a component with no way to receive what it reports; that is the component's gap to close (ADR 0002).
pointer: hand cursor while interactive and arrow otherwise; hover entry reports upward only while the pointer owns selection.
keyboard: none of its own; focused follows the host or parent focus and the ring shows whenever focus is held, however it arrived.
screen reader: none; the hosting control carries the role and name.
size: no footprint of its own; hover and press scales are factors and the focus radius follows the hosted body.
tokens: accent and the press and micro Motion set; `focusColor` carries a stronger semantic state so the ring never erases it.
motion: press response and micro ring settling with the standard easing; reduced motion shortens the durations.
not designed: content, layout or dismissal; it is feedback on a host that owns all three.
