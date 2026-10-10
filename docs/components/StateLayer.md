# StateLayer

The component that owns the five states; every interactive control forwards rest, hover, press, focus and disabled through it instead of inventing its own.
states: rest, hover, press, focus and disabled via hovered, pressed, focused and interactive; the response swells on hover and shrinks on press, and focus draws a one-pixel accent ring.
actions: enumerated `activate()` and a real tap share `clicked` on an unhosted, available, clickable layer; hosted templates own their activation. `hoveredEntered` reports genuine pointer entry; `clickable: false` keeps hover feedback while refusing press and click. Growth lands on the target and never grows a layout.
pointer: hand cursor while interactive and arrow otherwise; hover entry reports upward only while the pointer owns selection.
keyboard: none of its own; focused follows the host or parent focus and the ring shows whenever focus is held, however it arrived.
screen reader: none; the hosting control carries the role and name.
size: no footprint of its own; hover and press scales are factors and the focus radius follows the hosted body.
tokens: accent and the press and micro Motion set; `focusColor` carries a stronger semantic state so the ring never erases it.
motion: press response and micro ring settling with the standard easing; reduced motion shortens the durations.
expected: `manualHoverOverride` and `manualPressOverride` add host-supplied visual state, remain gated by availability, and never emit click or selection intent. Genuine pointer entry is reported independently of a held override. Template and geometry wiring follows caelestia `components/StateLayer.qml` and `components/controls/ButtonBase.qml`; the visual overrides are retained, but the native pointer fact remains separate to preserve selection intent.
not designed: content, layout or dismissal; it is feedback on a host that owns all three.
