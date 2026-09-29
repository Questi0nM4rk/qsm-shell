# Disclosure

A collapsible heading over an indented content slot; the host owns `expanded` and answers every toggle.
states: expanded and collapsed; the chevron rests at a right angle when open and flat when closed, and collapsed content is not laid out at all.
actions: pointer click, Space and Return on the heading emit `toggled(expanded)`; `expanded` never changes inside the component.
pointer: the whole heading is the target with a StateLayer swell on the chevron; wheel does nothing and propagates.
keyboard: tab reaches an enabled heading and Space and Return share the toggle route; the focus mark forwards to the StateLayer.
screen reader: no role of its own; the title names the region and the badge is supporting information.
size: heading at control small height with fixed row spacing; content is indented one box step; long titles elide rather than growing the heading.
tokens: controlHeightSm, space1, space2, space5, iconSm, radiusSm, text roles and Badge; no local colours or measurements.
motion: fast chevron rotation plus StateLayer hover and press swell; reduced motion shortens the duration.
not designed: selection, menu disclosure or asynchronous content; use Segmented, Menu or the host for those.
