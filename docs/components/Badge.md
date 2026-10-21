# Badge

A small marker that says what state a thing is in: a count on a corner, a status beside a name, an unread dot; meaning never travels in colour alone.
states: rest only, tinted or filled; `dot` is presence only, always neutral whatever `tone` says; the badge hides itself when dot, text and icon are all empty.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it never claims hover, press or wheel.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: static text named from `accessibleName`, else `text`; a dot or icon-only badge needs `accessibleName`; tone is a hue and hues alone are invisible to many readers.
size: fixed `badgeHeight` pill; a single character stays circular and longer text grows into a pill; the dot is a fixed small circle.
tokens: badgeHeight, spaceTight, space1, space2, iconXs, textXs, the semantic tone set, textOnPrimary and textMuted; no local colours or measurements.
motion: micro colour settling of fill and reading together on tone change or fill toggle; reduced motion shortens the duration.
not designed: interaction, dismissal, progress or a large banner; use Capsule, Callout or the host for those.

## UIX audit

Evidence: source-reviewed only. No live window, capture, accessibility tree or owner acceptance was used. Contrast values are arithmetic on the token hex values in `tokens/deep-night.json`, with sRGB blending assumed.

### Purpose and consequence

The task is to show a state a person must notice (a pending count, an unread presence, a status beside a name) without relying on hue alone. If it fails, a count is missed, or a status reads as the wrong state.

### Controls and states

Unit controls (`workbench/units/Badge.qml`): tone (six values), weight (tinted, filled), presence (reading, count 120, long, glyph, dot, empty).

- Implemented: all six tones, both weights, text, icon, dot, and hiding when empty (`Badge.qml:62`).
- Not implemented, by design: hover, press, focus, disabled. A `Rectangle` cannot take focus.
- Long reading: implemented as growth (BADGE-02).
- Unknown tone: throws, naming the value (BADGE-03, fixed).

### Routes

- Pointer: none. The component has no input handler; the host owns hover and press.
- Keyboard and focus: none. The component is not a tab stop and draws no focus ring, which is correct for a non-interactive marker.
- Accessibility: StaticText with `accessibleName` or `text` (BADGE-04, fixed). Criterion verdicts belong to a11y-audit and are not tested here.
- Wheel: none.

### Sizes, empty, long, failure

- Height: `badgeHeight` 16 px (`tokens/deep-night.json:116`).
- Count chip: `badgeWidth` 28 px for any numeric text (`Badge.qml:58`).
- Dot: `2 * spaceTight + space1`, which is 8 px (`Badge.qml:53`; `space.tight` 2, `space.1` 4).
- Empty: hidden (`Badge.qml:62`). Whitespace-only text shows an empty pill (H3).
- Long: width follows content (BADGE-02).
- Above 99: numeric text shows `99+` (`Badge.qml:50-51`). Non-numeric text is untouched.
- Failure: unknown tone (BADGE-03). Cancellation: none.

### Visual roles and palette pairs

- Fill: the tone colour. Tinted fill is the tone at `badgeTint` 0.18 over the layer (`Badge.qml:61`, `Style.qml:83`, `tokens/deep-night.json:84`).
- Text on tinted: the tone itself. Text on filled: `textOnPrimary` (`Badge.qml:45`).
- Neutral tone: `textMuted` (`Badge.qml:39`).
- Reading size: `textXs`, which is 10 px (`Badge.qml:85`, `type.xs` 10). Body-text rule applies: 4.5 needed.

Contrast, computed from token values (WCAG 2.2, 1.4.3 text 4.5, 1.4.11 non-text 3):

| tone | tinted text on band | on surface | on overlay | filled text on fill |
| --- | --- | --- | --- | --- |
| neutral | 5.80 | 4.09 | 3.29 | 8.61 |
| accent | 5.92 | 4.19 | 3.37 | 8.87 |
| success | 6.20 | 4.39 | 3.53 | 9.41 |
| warning | 6.04 | 4.28 | 3.44 | 9.13 |
| danger | 5.91 | 4.19 | 3.37 | 8.84 |
| info | 6.17 | 4.36 | 3.52 | 9.32 |

The dot on band is 8.6 to 9.4 against the layer. On overlay the lowest, info, is about 4.9 (hand arithmetic, same formula).

### Motion and reduced motion

- `Behavior on color` (fill) and `Behavior on _ink` (reading), `ColorAnimation` with `Motion.micro` (130 ms, `Motion.qml:26`, `tokens/deep-night.json:54`) and `Motion.standardEasing` (`Motion.qml:120`, OutCubic).
- Reduced motion: 60 ms, the colour still settles (`Motion.qml:26`). It shortens and does not remove the change.
- Review-animations verdict: Approve; BADGE-06 is fixed in source. The feel is not judged from code; it needs a slow-motion check at 2 to 5 times the duration, frame by frame.

### Pointer geometry

Not applicable. The component has no input shape, so there is no D, no W and no ID to state. The painted body is 16 px tall and 16 to 28 px wide. A host that makes a badge clickable must add its own input area. The pointer floor is 24 by 24 px (WCAG 2.5.8, as used in ux-audit check 3), and a 16 px badge alone misses it. Fitts ID = log2(1 + D/W) needs D from a real host layout; the width model would be W as the smaller side of the input (assumed). No value is claimed here. Label origins and weights: not applicable.

### Findings

Source-backed defects:

- BADGE-01, medium, shared. The tinted weight fails 4.5 on `surface` for all six tones (4.09 to 4.39) and on `overlay` (3.29 to 3.53). Evidence: contrast table above, `Badge.qml:61`, `Badge.qml:85`, `tokens/deep-night.json:84`. A person on a card sees a faint 10 px tinted label. Fix: a per-tone tinted text colour mixed toward `text` until 4.5 holds on `overlay`, or a lower tint, both as tokens.
- BADGE-02, medium, shared. Width follows content with no ceiling (`Badge.qml:56-59`), so the `Prose` ElideRight (`Prose.qml:118`) never fires. A long reading stretches the chip across its row and moves its siblings. This breaks AGENTS.md definition of done item 5. Fix: a maximum width from a token, with the text elided inside it.
- BADGE-03, low, fixed (source-reviewed, load-checked). An unknown tone silently becomes neutral (`Badge.qml:33-40`, default at 39). A typo such as `danger` misspelt renders grey, so the state is lost with no signal. Against the implementation rule's one-path, fail-loud rule. Fix: fail loud through the project error system, naming the bad value. Now an unknown tone throws `Badge: unknown tone "<value>"` from `_tone`; there is no fallback.
- BADGE-04, medium, fixed (source-reviewed, load-checked). No accessible name anywhere in `Badge.qml`. The icon-only form (`Badge.qml:74-79`) and the dot (`Badge.qml:25-27`, `71`) give a screen reader nothing. Whether the `Prose` text is exposed is unknown until the tree is read (H4). Fix: a role and a name from `text`, plus a host-supplied `accessibleName` for dot and icon. Now `Accessible.role` StaticText, name from `accessibleName` else `text`, ignored when hidden; a visible dot or icon-only badge without `accessibleName` warns.
- BADGE-05, low, fixed (source-reviewed, load-checked). Dot is documented as presence only (`Badge.qml:25-26`), but `Badge.qml:61` still colours it by tone, so a red dot and a grey dot mean different states. That is the hue-only meaning the header rules against (`Badge.qml:13-14`). Fix: when `dot` is set, use a fixed neutral tone, or state the exception in the comment. Now `dot` ignores `tone` and is always `textMuted` (`_hue`).
- BADGE-06, low, fixed (source-reviewed, load-checked). The fill animates over 130 ms (`Badge.qml:61`, `64-66`) while the text colour `_prose` (`Badge.qml:45`, `Prose` colour at `86`) switches at once. On a tone change or a fill toggle, the text sits on a half-faded fill. Fix: animate the text colour with the same `Motion.micro` behaviour. Now the reading follows `_ink`, which carries the same `Motion.micro` behaviour.
- BADGE-07, low, shared. A literal `2` in the dot size (`Badge.qml:53`) is a measurement typed in a component. Fix: a dot-size token in the `Style` set.
- BADGE-08, low, fixed (source-reviewed, load-checked). The unit has no long reading and no count above 99 (`workbench/units/Badge.qml:44-48`, reading fixed at `"3"`). Long and overflow cases cannot be reached in the window, so BADGE-02 and the `99+` cap are invisible to the owner. Fix: add a long reading and a `"120"` option to the presence control. The presence control now has `count 120` and `long`.

Redesign proposals:

- The tinted weight is the default, and a host that wants a count noticed passes `filled: true`. The owner can decide whether the tinted default should exist at all; if it stays, BADGE-01 is its fix.
- The `99+` cap is written twice: in the component (`Badge.qml:51`) and in `Rail.qml`'s text binding. One owner should remain, most naturally the component, with consumers passing the number.
- Radius is `height / 2` (`Badge.qml:60`). The token set already has `radius.pill` 999 (`tokens/deep-night.json:35`). Using it removes a derived value from the component.
- Keep the fixed `badgeWidth` chip for counts. The chip is a known pain beside 16 px glyphs, so any change there needs runtime judgement.

Source conflicts:

- This record says "a single character stays circular" (line 9). `Badge.qml:58` gives any numeric text the 28 px chip, and the comment at `Badge.qml:47-49` says so on purpose. The code's own intent contradicts this record; the owner decides, and the record should follow the decision.
- This record says "longer text grows into a pill" (line 9). AGENTS.md definition of done item 5 says natural size is a constant, which BADGE-02 contradicts. AGENTS.md is binding; the record should change unless the owner rules otherwise.
- This record says motion is "micro colour settling on tone change" (line 11). The same behaviour also runs on the filled toggle (`Badge.qml:61`, `64-66`).

Hypotheses (not measured):

- H1: the reading sits on the optical centre of the 16 px body. The content row is centred by `anchors.centerIn` (`Badge.qml:70`), with default child alignment; the vertical position of the glyph against the digits is unmeasured.
- H2: `99+` in 10 px tabular text fits the 28 px chip. Not measured.
- H3: whitespace-only text (`" "`) passes `text.length > 0` (`Badge.qml:62`) and shows an empty pill.
- H4: `Prose` text may be reported as static text by the platform tree without any `Accessible.*` on Badge. Unknown until read by a11y-audit.
- H5: contrast over layers other than band, surface and overlay (for example the primary or a 0.4 lifted hover per the surface ladder) is not computed.

Not examined: live window, captures, glyph rendering (offscreen capture does not rasterise `SvgIcon`; the `check` glyph exists at `qml/QsmShell/assets/icons/check.svg`), accessibility tree, reduced-motion runtime, text scaling, colour-vision simulation, surfaces in place. Caelestia has no badge sibling in `~/Clonned/caelestia/repo/components/controls/`, so no comparison was made.

Evidence: source-reviewed. Runtime-exercised: none. Owner-accepted: none.
