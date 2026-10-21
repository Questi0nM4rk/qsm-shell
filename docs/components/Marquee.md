# Marquee

Overflowing text that travels once, always or on hover; at rest it elides like any other line.
states: travelling and resting; travel starts only while the text overflows and the mode wants it, and rest elides on the right.
actions: none; no signals and no programmatic route; changing the text re-arms a single pass in `once` mode.
pointer: hover mode reads a HoverHandler and claims nothing; other modes ignore the pointer and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: the full text is the announcement; travel is visual and never the only channel.
size: the host's width clips the line; implicit width is the constant `Style.controlWidth`, never the text's; travel distance is the overflow and nothing else.
tokens: the Prose role colour (`muted` forwarded, no colour property) and the Motion durations for dwell, scroll and return; no local colours or measurements.
motion: dwell, scroll and return in sequence with the move easing; single pass or infinite by mode; every mode rests as an ellipsis under reduced motion; leaving mid-pass returns from the current position; an unknown `mode` logs an error.
not designed: wrapping, editing or paced tickers independent of overflow; use Prose or the host for those.

## UIX audit

Evidence: source-reviewed only. No runtime, no capture, no owner acceptance. Values are read from
`tokens/deep-night.json` (md scale); the reduced-motion values come from `Motion.qml` when
`Style.reducedMotion` is true. Nothing is sampled.
Design source: `design/MASTER.md` does not exist in this repository; the expected column cites
`tokens/deep-night.json`, `AGENTS.md` and the comments in `Motion.qml` and `Prose.qml`.

**Purpose and consequence.** Shows a line that is longer than its room, so a title or status is
readable at the moment it changes, and rests as an ellipsis otherwise. Consequence of failure: a
person reads a truncated title, or a reader that scrolls forever in the corner of the eye.

**Expected controls and states.** Expected: `mode` (once, always, hover, never), `text`, `role`,
`muted`, `width` from the host. Implemented: `mode`, `text`, `role`, `muted`. States: resting and travelling, each in the four modes; overflowing and fitting.
Controls in `workbench/units/Marquee.qml:27-34` cover `mode` only (see D1).

**Routes.** Pointer: hover mode only, through `HoverHandler` (`Marquee.qml:62`), claims nothing.
Keyboard: none, not a tab stop, correct for non-interactive text. Wheel: no handler, passes through.
Focus: none, no ring, correct for non-interactive text. Screen reader: no `Accessible` property set
in source; the full name relies on Qt `Text` defaults, unverified, a11y-audit's verdict.

**Sizes, content, failure, cancellation.** Implicit size is the constant `Style.controlWidth`. Empty
text: `label.implicitWidth` is 0, nothing overflows, nothing travels. Long text: travel equals the
overflow. Cancellation: a text or mode change resets `label.x` to 0; leaving hover mid-pass settles
back from the current position over `Motion.medium`. A mode outside the four logs an error and never
travels.

**Visual roles and palette pairs.** Default role `label`: `Style.text` (#f0ecf5) on `Style.band`
(#271e30), computed from the token hex: 12.3:1, passes 4.5:1 for body text. The metadata role is
`Style.textMuted` (#c5bad1) on band, 7.8:1; `muted` forwards to Prose so the role decides the
colour. Font family is not read here (`Style.fontFamily` is in `Style.qml`, not checked); weight is
assumed Medium (`Style.weightMedium`, Prose's default for `label`). Size: `Style.textSm` (12 px).

**Motion and reduced motion.** Token values at md: `Motion.large` 400 ms, `Motion.medium` 260 ms.
Each pass: dwell `Motion.readingDwell` (800 ms), forward at `Motion.readingPace` (16 ms per px) with
a `Motion.large` floor, dwell, return at the same pace with a `Motion.medium` floor. Every mode
rests as an ellipsis under reduced motion.

**Pointer geometry (assumptions, labelled).**
- Input shape: the root rectangle. Width is the host width (the unit uses `Style.controlWidth`, 380
  px from `geometry.controlWidth`). Height is the line box H, assumed 16 px for a 12 px line (not
  measured).
- Painted size: the glyph run, width `min(text width, host width)`, height inside H. For short
  text the input is wider than the paint by (host width minus text width); not computed, because
  the text width is content.
- Origin assumptions: the input origin is the item's top-left. The unit centres the item, so the
  origin there is the centre anchor; the label origin is x 0, y 0 of the item.
- Width model: W is the vertical extent H, because the approach to a row is vertical from its
  neighbours. The horizontal extent is the host width and is not the Fitts W in this model.
- D is the centre-to-centre distance from the previous target. The component does not know its row
  pitch P, so D = P is an assumption.
- ID = log2(1 + D/W): with no gap (P = H), ID = 1.00 bit; P = 2H, ID = 1.58 bits; P = 3H, ID = 2.00
  bits. Landing tolerance is ±H/2 = ±8 px vertically.
- Neighbouring interference: the component adds no gap, so adjacent rows' hover zones abut. The
  host sets the gap, so the interference depends on it.
- Popup corridor: not applicable, there is no popup.

### Source-backed defects

- **D1, minor (unit).** `workbench/units/Marquee.qml:27-34` exposes `mode` only. Content is never
  empty, never short enough to fit, and never a second role, so the supported cases AGENTS asks
  for are not reachable from the harness. `workbench/stories.json:300-316` holds one key,
  `marquee`, with `variant: "always"`, so the component default `once` has no catalog story. Fix:
  add a text option (empty, fitting, long) to `controls`, and a `once` story key. Shared: yes, the
  story key lives in `workbench/stories.json`, which is on the shared list.

### Proposals (taste, not defects)

- The return and the forward pass could share an easing. Motion's rule is that constant motion is
  linear (review-animations standard 3); the current `Motion.moveEasing` (InOutCubic) slows the
  text at both ends of every pass. Owner ruling.
- A dwell of 800 ms at each end of a 300 px pass is a 6.7 s cycle. Owner should judge the
  reading time.
- Under reduced motion the overflow is never readable on screen. The remaining question is a
  non-moving reveal (a fade or a wrap). Owner ruling.
- The component has no known consumer yet; keep or remove is the owner's call.

### Hypotheses (observed nowhere, measured nowhere)

- H1: a Marquee created with its text already set may not play its once pass on first show, since
  `onTextChanged` may not fire during construction. Runtime check needed.
- H2: a mid-pass text change keeps the old pass's `to` and `duration`, because
  `NumberAnimation` reads them at start. The documented "re-arms a single pass" would then be false
  until the pass ends. Runtime check needed.
- H3: the full text is announced through Qt's default `Text` accessible name, as the record
  claims. Not verified; a11y-audit owns the tree check.
- H4: a 16 px line box clips tall diacritics if the font's ascent is short, because the clip box is
  `implicitHeight` (`:37`). Depends on the font, which is not read here.
- H5: a 2.2.2-style concern (moving content with no pause, a Level A criterion in WCAG 2.2) applies to
  `always`. The verdict belongs to a11y-audit; no criterion is decided here.

### Not examined

- Runtime, captures, pointer, wheel, focus, screen reader, and every reduced-motion toggle. None
  was run, per the audit rules.
- Font family and weight (`Style.fontFamily` is not read).
- A caelestia sibling: a search of `~/Clonned/caelestia/repo` found no marquee or ticker.
- The unit's behaviour in the live preview.
