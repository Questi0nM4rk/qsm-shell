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
Controls in `workbench/units/Marquee.qml:27-34` cover `mode` only (see D13).

**Routes.** Pointer: hover mode only, through `HoverHandler` (`Marquee.qml:62`), claims nothing.
Keyboard: none, not a tab stop, correct for non-interactive text. Wheel: no handler, passes through.
Focus: none, no ring, correct for non-interactive text. Screen reader: no `Accessible` property set
in source; the full name relies on Qt `Text` defaults, unverified, a11y-audit's verdict.

**Sizes, content, failure, cancellation.** Implicit size is the text's own width (`Marquee.qml:35`,
see D5). Empty text: `label.implicitWidth` is 0, nothing overflows, nothing travels. Long text:
travel equals the overflow. Cancellation: a text or mode change resets `label.x` to 0
(`Marquee.qml:45-49`); leaving hover mid-pass snaps back (D4). A mode outside the four is silent
(D7).

**Visual roles and palette pairs.** Default role `label`: `Style.text` (#f0ecf5) on `Style.band`
(#271e30), computed from the token hex: 12.3:1, passes 4.5:1 for body text. The metadata role would
be `Style.textMuted` (#c5bad1) on band, 7.8:1, but the forwarded `color` overrides it (D6). Font
family is not read here (`Style.fontFamily` is in `Style.qml`, not checked); weight is assumed
Medium (`Style.weightMedium`, Prose's default for `label`). Size: `Style.textSm` (12 px).

**Motion and reduced motion.** Token values at md: `Motion.large` 400 ms, `Motion.medium` 260 ms.
Each pass: dwell 800 ms (`Marquee.qml:27`, `Motion.large * 2`), forward at 16 ms per px with a
400 ms floor (`:78`), dwell 800 ms, return 260 ms over any distance (`:86`). Forward speed at 300 px
of travel is 62.5 px/s; the return is 1154 px/s, 18.5 times faster (D3). Reduced motion
(`Motion.large` 120, `Motion.medium` 100): once and hover never travel (`:32-33`); always still
loops (D1), with a loop period of 5380 ms against 6660 ms at 300 px travel (D1).

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

Fixed items below keep their original finding for the reasoning. What changed: D1 `always` is gated
on `!Style.reducedMotion` like the other modes and rests as an ellipsis; D4 a stop mid-pass runs a
`Motion.medium` settle from the current `label.x` (placed directly under reduced motion); D5
`implicitWidth` is `Style.controlWidth`; D6 `color` is replaced by `muted`, forwarded to Prose; D7
an unknown `mode` logs `console.error` (the Callout form) and never travels; D8 the once pass is
armed after layout, only if the text overflows. None is owner-accepted.

- **D1, major. Fixed (source-reviewed, load-checked).** `always` ignored reduced motion: `Marquee.qml:32` tests `mode === "always" ||`
  before `!Style.reducedMotion`, and the loop (`:66`, `Animation.Infinite`) runs. The loop period
  also shortens under reduced motion: `Motion.large * 2` (`:27`, `:70`, `:81`) falls from 800 to 240
  ms, so the period drops from 6660 to 5380 ms at 300 px travel. AGENTS requires a loop to lengthen
  under reduced motion and respects `Style.reducedMotion`. What a person sees: a title in the
  always mode keeps moving for a person who asked for less movement, and moves faster. Fix: gate
  `always` on the same reduced-motion check, and make the stop path a rest with an ellipsis.
  Shared: no.
- **D3, major.** Return snap: `Marquee.qml:86` uses `Motion.medium` (260 ms) for any travel, while
  the forward pass uses 16 ms per px (`:78`). At 300 px the return is 18.5 times faster than the
  forward pass, a visible whip at the end of every pass. Fix: derive the return from the same pace,
  with the pace as a `Motion` token. Shared: yes, the token lives in `qml/QsmShell/Style/Motion.qml`.
- **D4, major. Fixed (source-reviewed, load-checked).** Hover exit snap: `Marquee.qml:68`, `onRunningChanged: if (!running) label.x = 0`.
  Stopping mid-pass, by leaving hover in hover mode or by the text shrinking to fit, moves the text
  from its mid-travel position to 0 in one frame. What a person sees: the title jumps back when
  the pointer leaves it. Fix: return from the current `label.x` with a short animation, not an
  assignment. Shared: no.
- **D5, major. Fixed (source-reviewed, load-checked).** Content-derived natural width: `Marquee.qml:35`, `implicitWidth:
  label.implicitWidth`. AGENTS: a text box's preferred width is a constant, and natural size is a
  constant so long content scrolls or elides and never grows the control. A host that sets no width
  gets a row as wide as the full title, so the title pushes its siblings or overflows its container.
  The unit sets `width`, so the catalog hides this. Fix: a constant preferred width (a `Style`
  value, read only). Shared: no.
- **D6, minor. Fixed (source-reviewed, load-checked).** Forwarded colour overrides the role's colour: `Marquee.qml:24` sets
  `property color color: Style.text`, and `:54` forwards it to Prose. Prose's own binding
  (`Prose.qml:65`) gives `Style.textMuted` for `metadata`, `supporting` and `section`. Prose's own
  comment says a call site sets `color` only when it needs a colour (`Prose.qml:44-46`). What a
  person sees: a `metadata` line in a Marquee is as loud as the title (12.3:1, not 7.8:1). Fix:
  remove `color` from Marquee and expose `muted`, forwarded to Prose. Shared: no.
- **D7, minor. Fixed (source-reviewed, load-checked).** Silent unknown mode: `Marquee.qml:31-33` and `:47`. A value outside once, always,
  hover, never (for example `"Always"`) never travels, never warns, and never fails. The same
  shape elsewhere (`Style.size`) warns once; here nothing does. Fix: validate at ingress and fail
  loud with a named error, per the implementation rule. Shared: no.
- **D8, minor. Fixed (source-reviewed, load-checked).** Stale pending pass: `Marquee.qml:47` sets `run.pending` on any text change in once
  mode. It is cleared only in `onFinished` (`:67`), which runs only for a pass that played. A text
  that fits leaves `pending` true, and a later resize that makes it overflow plays a pass nobody
  asked for. Fix: set `pending` only when `overflows`. Shared: no.
- **D9, minor.** Numbers in the component: `Marquee.qml:27` (`* 2`) and `:78` (`* 16`). AGENTS
  requires every number to come from `Style` or `Motion` (definition of done item 6, "no numbers in
  a component"). Fix: `Motion` tokens for dwell and pace. Shared: yes, `Motion.qml`.
- **D13, minor (unit).** `workbench/units/Marquee.qml:27-34` exposes `mode` only. Content is never
  empty, never short enough to fit, and never a second role, so the supported cases AGENTS asks
  for are not reachable from the harness. `workbench/stories.json:300-316` holds one key,
  `marquee`, with `variant: "always"`, so the component default `once` has no catalog story. Fix:
  add a text option (empty, fitting, long) to `controls`, and a `once` story key. Shared: yes, the
  story key lives in `workbench/stories.json`, which is on the shared list.

### Source conflicts

- `docs/components/Marquee.md` line 3 and line 11 say "single pass or infinite by mode" and "a
  one-shot position change is removed under reduced motion". The first is true, the second holds
  for once and hover only. AGENTS requires the reduced-motion form of `always` too (D1). This is
  one project's record against AGENTS, not two owners, so no `source-conflict` tag is needed.

### Proposals (taste, not defects)

- The return and the forward pass could share an easing. Motion's rule is that constant motion is
  linear (review-animations standard 3); the current `Motion.moveEasing` (InOutCubic) slows the
  text at both ends of every pass. Owner ruling.
- A dwell of 800 ms at each end of a 300 px pass is a 6.7 s cycle. Owner should judge the
  reading time.
- Under reduced motion the overflow is never readable on screen (`Marquee.qml:32-33`). AGENTS
  requires that the one-shot position change is removed. The remaining question is a non-moving
  reveal (a fade or a wrap). Owner ruling.
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
