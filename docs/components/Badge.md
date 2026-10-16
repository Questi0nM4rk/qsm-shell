# Badge

A small marker that says what state a thing is in: a count on a corner, a status beside a name, an unread dot; meaning never travels in colour alone.
states: rest only, tinted or filled; `dot` is presence only, never a distinguishable state; the badge hides itself when dot, text and icon are all empty.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it never claims hover, press or wheel.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: the text or icon carries the meaning; tone is a hue and hues alone are invisible to many readers.
size: fixed `badgeHeight` pill; a single character stays circular and longer text grows into a pill; the dot is a fixed small circle.
tokens: badgeHeight, spaceTight, space1, space2, iconXs, textXs, the semantic tone set, textOnPrimary and textMuted; no local colours or measurements.
motion: micro colour settling on tone change; reduced motion shortens the duration.
not designed: interaction, dismissal, progress or a large banner; use Capsule, Callout or the host for those.
