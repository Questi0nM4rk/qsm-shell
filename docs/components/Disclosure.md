# Disclosure

A collapsible heading over an indented content slot; the host owns `expanded` and answers every toggle.
states: expanded and collapsed; the chevron rests at a right angle when open and flat when closed, and collapsed content is not laid out at all.
actions: enumerated `toggle()` reports `toggled(!expanded)`; the native heading button, Space, Enter/Return, accessibility and callers share it. `expanded` never changes inside the component.
pointer: the whole heading is the target with a StateLayer swell on the chevron; wheel does nothing and propagates.
keyboard: tab reaches an enabled heading and Space and Return share the toggle route; the focus mark forwards to the StateLayer.
screen reader: one named toggle-button heading reports checked state and an Expanded/Collapsed description; the badge is supporting information.
size: heading at control small height with fixed row spacing; content is indented one box step; long titles elide rather than growing the heading.
tokens: controlHeightSm, space1, space2, space5, iconSm, radiusSm, text roles and Badge; no local colours or measurements.
motion: fast chevron rotation plus StateLayer hover and press swell; reduced motion shortens the duration.
source: compared caelestia `ButtonBase.qml`'s StateLayer activation; rejected its internal toggle state and palette. Qt's native AbstractButton supplies heading input/focus while the host keeps expansion.
expected: enumerated `toggle()` is the single pointer, Space, Enter and programmatic route. It reports `toggled(!expanded)` once without writing host state, refuses when unavailable, and exposes one named focusable heading with expanded accessibility state.
not designed: selection, menu disclosure or asynchronous content; use Segmented, Menu or the host for those.
