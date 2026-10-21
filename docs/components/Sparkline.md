# Sparkline

A small trend line with an optional area fill; it shows shape at a glance and takes no input.
states: none; line or filled area by flag, with explicit minimum and maximum or automatic extents from the values; a flat series centres; empty is a floor baseline, one point is a dot at the end; values clamp to a pinned extent.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: no role of its own; the surface owning the metric announces the reading.
size: twice the large control height by the small control height; stroke defaults to a twelfth of the height; round caps and joins throughout.
tokens: accent only; no local colours or measurements.
motion: none; it repaints on values, colour, area, extents and size.
not designed: axes, labels, interaction or precise readout; use Stat, Prose or the host for those.

## UIX audit

Evidence: source-reviewed only. No capture, no live geometry and no running session were used, so every
number below comes from tokens and code, not from pixels. Owner acceptance: none. Themes: deep-night
tokens only (`tokens/deep-night.json`); light and dark parity cannot be examined from source.

### Purpose and consequence

Shows the shape of one series (climbing, settled, spiking) beside the number the host states. The person
reads a trend at a glance. A wrong shape here leads to a wrong conclusion about load or traffic, and an
empty box that looks like a broken graph makes the host card look faulty.

### Controls and states

- Public surface: `values`, `color` (default `Style.accent`), `minimum` and `maximum` (NaN means take from
  the data), `area`, `thickness` (0 means derive from height). All six are read in `onPaint` and each has
  a repaint trigger (`Sparkline.qml` 18-30, 84-95).
- Implemented: normal series, flat series (centred), pinned extents, area and line, stated and derived
  weight.
- Empty series paints a baseline at the floor, one point paints a dot at the end, and a value beyond a
  pinned extent sits on that extent.
- No pointer, focus, press, hover, disabled, selected, loading or error state exists. The five-state law
  applies to interactive types; this type states that it has none rather than inventing them.

### Routes

- Pointer: none. The Canvas has no input handler, so clicks and wheel pass to the host.
- Keyboard: none. Default focus policy, never a tab stop.
- Screen reader: no role or name; the owning surface carries the reading (`docs/components/Sparkline.md`
  line 8). Criteria are a11y-audit's and were not run.
- Programmatic: properties only; `integration.actions` is empty in `workbench/units/Sparkline.qml` 49-51.

### Sizes, empty, long, failure

- Natural size: 96 x 32 (`Style.size("Sparkline", "lg")` 48 x 2 by `Style.size("Sparkline", "sm")` 32;
  `Sparkline.qml` 39-40). No size preset; a host sets the size from its layout.
- Empty: baseline at the floor. One point: a dot at the end. Long: no cap in the library; a host caps its own history.
- Failure: `NaN` in values propagates silently through `Math.min`/`Math.max` and `yOf`; no guard
  (hypothesis H1). Maximum below minimum inverts the line with no signal (proposal P3).
- Cancellation: none; no asynchronous work.

### Visual roles and palette pairs

- Line: accent `#d9b4ea` on band `#271e30` is 8.87:1, computed from token hex values (not sampled from
  pixels). The line is the data mark, so it needs 3:1 (WCAG 2.2, 1.4.11); it passes on the source values.
- A second series in `Style.info` `#89cff1` on band is 9.32:1.
- Area fill: accent at alpha 0.18 over band composites to `#473951`; accent over that is 5.92:1. The
  alpha is a literal (spk-1).
- Component reads only `Style`; a retheme changes the line through `Style.accent`.

### Motion

None. The Canvas repaints when value, colour, area, thickness, extents, width or height change
(`Sparkline.qml` 88-95). No animation, no `Motion` token, so reduced motion has nothing to shorten.
review-animations was not run because there is no motion.

### Pointer geometry

- Input shape: none. The item claims no pointer events; hit area equals nothing.
- Painted size: 96 x 32 by default (Control `lg` x 2 by Control `sm`). A host's box usually fills its
  layout cell.
- Label origins and weights: no label on this type; no origin assumption is needed.
- D, W and ID: not defined, because no target exists. If a host makes the box a target, the width model is
  the short side of the painted box (32 px at md), D is the host's trigger-to-box distance (not in source),
  and ID = log2(1 + D/W). No value is computed because D is unknown and no host target exists.
- Landing tolerance: none. Neighbouring interference: none, since the item cannot take a hover from a
  neighbour. Trigger-to-panel corridor: not applicable (no popup).

### Findings

| id | pass | element | evidence (source) | expected (source) | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| spk-1 | 6 and 4, tokens | area fill | `Sparkline.qml` 69 literal `0.18` | `docs/components/Sparkline.md` line 10: accent only, no local measurements | fill alpha not in the token set | minor |

spk-1 needs a shared token change.

- spk-1 (minor, shared true): `Sparkline.qml` 69. The 0.18 alpha is not a token, so a token change cannot
  reach the fill and the doc's "no local measurements" is false. Fix: add an `opacityArea` token in
  `tokens/deep-night.json` and `Tokens.qml`, expose it through `Style`, and read it here.

Source conflicts (the owner decides which wins):

- SC1: `Sparkline.qml` 49-51 and the doc's "a flat series centres" (line 4) vs a host's wish that idle read as quiet. A flat zero series is drawn at mid height, which reads as a steady
  middle value, the opposite of quiet. A rule for floor-valued flats would resolve it.

Proposals (taste and redesign; no defect):

- P1: decide one empty and one-point visual for every trend in the library, so no host has to draw its own.
- P2: the size is implicit from control tokens with no preset (`Sparkline.qml` 39-40). Decide whether the
  type is sized (then `Style.size("Sparkline", size)`) or fills its host (then drop the implicit size). It
  does both today.
- P3: a maximum below the minimum should fail loud, not invert the line silently (no guard, lines 36-37 and 56).
- P4: a derived stroke of height/12 gives 2.67 px at md, a fraction that antialiases unevenly. Round to whole
  pixels, if a zoomed capture confirms it.
- P5: a host may set a 1.5 px stroke on a 56 px box. The owner judges whether such a line is too faint.
- P6: `values` triggers only on reassignment, not mutation. A host that reassigns is correct; the doc
  should say "assign a new array".
- P7: no text alternative sits inside the component; the owning surface carries the number. a11y-audit
  decides what the criteria require.

Hypotheses (unmeasured, not in the table):

- H1: `NaN` in values (for example from a first rate sample) yields no line and no error.
- H2: `Math.min(...values)` throws past the engine's argument limit for very long arrays; not reachable with
  short histories.
- H3: a 2.67 px stroke at md may show uneven antialiasing (P4).

Not examined: live geometry (no session was started, by request); screenshots and zoom crops; every theme
except deep-night; light and dark parity; keyboard, focus and screen-reader routes (a11y-audit's); motion
(none); pointer timing (no target). Accessibility criteria are a11y-audit's; run it for this surface.
