# Disclosure

A collapsible heading over an indented content slot; the host owns `expanded` and answers every toggle.
states: expanded and collapsed; the chevron rests at a right angle when open and flat when closed, and collapsed content is not laid out at all.
actions: enumerated `toggle()` reports `toggled(!expanded)`; the native heading button, Space, Enter/Return, accessibility and callers share it. `expanded` never changes inside the component.
pointer: the whole heading is the target with a StateLayer swell on the chevron; wheel does nothing and propagates.
keyboard: tab reaches an enabled heading and Space and Return share the toggle route; the focus mark forwards to the StateLayer.
screen reader: one named button heading that is `expandable` and `expanded`; the badge is its description.
size: heading at Control sm height (32 px) with its content inset `space2` each side; the body hangs from the title's left edge and stops at the content's right edge, 12 px below the heading; long titles elide rather than growing the heading.
tokens: the Control size table, space1, space2, iconSm, Motion.pressScale, radiusSm, text roles and Badge; no local colours or measurements.
motion: `Motion.fast` chevron rotation plus StateLayer hover and press swell; reduced motion removes the rotation (the chevron snaps) and shortens the rest.
source: compared caelestia `ButtonBase.qml`'s StateLayer activation; rejected its internal toggle state and palette. Qt's native AbstractButton supplies heading input/focus while the host keeps expansion.
expected: enumerated `toggle()` is the single pointer, Space, Enter and programmatic route. It reports `toggled(!expanded)` once without writing host state, refuses when unavailable, and exposes one named focusable heading with expanded accessibility state.
not designed: selection, menu disclosure or asynchronous content; use Segmented, Menu or the host for those.

## Measured

Unit `disclosure` in a headless slot at scale 1.25, 380 px wide with long content:

- Heading 32 px (Control sm), content inset 8 px each side: chevron box at x 8, icon at 32, title at x 56 (8 + 16 + 8 + 16 + 8), badge right edge at 372; the body hangs from x 56, 12 px below the heading (4 gap + 8 top), and stops at 372 so both share one right edge.
- A long title elides inside its row (276 px between icon and badge) and the heading stays 380 px wide; a body given `Layout.fillWidth` wraps inside the width left (324 px) instead of widening the group.
- The whole 380 x 32 heading is the target; a click on the title, on the badge, Space and Enter all call `toggle()` once (flow `disclosure-pointer`, native pointer and keys, offscreen and in a window); a mouse click leaves `focused` false, so the ring is the keyboard's.
- Under reduced motion the chevron snaps; the body always snaps.

## Open

- A disabled heading dims chevron, icon and label by colour; its `Badge` stays at full strength until `Badge` can dim.
- The body snaps open while the chevron turns; a reveal needs a clip that would shave the focus rings of the content inside it.
