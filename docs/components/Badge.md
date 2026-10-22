# Badge

A small marker that says what state a thing is in: a count on a corner, a status beside a name, an unread dot; meaning never travels in colour alone.
states: rest only, tinted or filled; `dot` is a filled circle that takes `tone` (neutral by default), because a 12 % tint of an 8 px disc is not a mark; the badge hides itself when dot, text and icon are all empty.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it never claims hover, press or wheel.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: static text named from `accessibleName`, else `text`; a dot or icon-only badge needs `accessibleName`; tone is a hue and hues alone are invisible to many readers.
size: fixed `badgeHeight` pill. A count (digits, "99+" past 99) takes the fixed `badgeWidth` chip in the technical face; any other reading is a word in the UI face, one end radius of air each side, and elides at a third of `controlWidth` (128 px); a lone glyph is the 16 px circle; the dot is `badgeDot`.
tokens: badgeHeight, badgeWidth, badgeDot, spaceTight, space4, iconXs, the semantic tone set, textOnPrimary and textMuted; no local colours or measurements.
motion: micro colour settling of fill and reading together on tone change or fill toggle; reduced motion shortens the duration.
not designed: interaction, dismissal, progress or a large banner; use Capsule, Callout or the host for those.
measured (rendered, scale 1.25): reading 8.6 to 8.9:1 tinted and 8.6 to 9.4:1 filled on every tone over the band, and 5.1:1 or better tinted over an overlay card (from the tokens); the dot against the band 8.6:1 neutral, 8.8:1 danger; "Reconnecting to the network" is 128 px wide and elided; a word has 8 px of air a side; a lone glyph is 16 by 16; a count and its chip centre within 0.5 px.
