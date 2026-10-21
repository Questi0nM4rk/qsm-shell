# Divider

One rule: a straight line of whole device pixels; decorative separation and nothing else.
states: none; it is never hovered, pressed, focused, selected or disabled.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; a decorative rule with no accessible name.
size: the thickness is `Style.stroke(Style.hairline, root)`, one device pixel at any scale, and the implicit height is that thickness; the drawn line insets symmetrically (`inset`) so anchored and fixed-width consumers behave alike; the item may claim a gap while the ink stays one line.
tokens: `textMuted` at `strength`, which is `Style.dividerOpacity` (0.35) inside a surface and `Style.dividerBandOpacity` (0.8) when `inBand` is set, where nothing but the rule groups what sits on it; no colour or thickness override.
motion: none.
not designed: labelled separators, interactive structure or spacing; use ListRow header rows, Section or layout gaps for those.

## Contract

- Properties: `inset` (0), `inBand` (false) and `strength` (derived from `inBand`). All are implemented; the line is a
  radius-0 Rectangle, so its edges snap to the device grid and it paints the same rows wherever it sits.
- The unit (`workbench/units/Divider.qml`) shows a surface rule, a list heading, a card rule, a short rule,
  a band rule and a turned band rule, with `inBand` on and off and three insets.

## Derived values

Contrast of the rule against its ground, `textMuted` #c5bad1 composited at `strength`:

| ground | strength | line colour | ratio |
| --- | --- | --- | --- |
| band #271e30 | 0.35 (default) | #5e5568 | 2.26 |
| band #271e30 | 0.8 (band rule) | #a59bb1 | 6.03 |
| surface #3b3145 | 0.35 | #6b6176 | 2.10 |
| overlay #4c4357 | 0.35 | #766d82 | 1.90 |

The rule is decorative, so no 3:1 requirement applies (WCAG 1.4.11 covers non-text content that carries
meaning).

## Open

- Lightness alone separates containers (AGENTS.md, surface ladder). Whether a separator between rows is
  content or a forbidden line is the owner's ruling; the library draws it as content.
- Vertical orientation is deferred: a rotated item is the only route to a vertical rule.
