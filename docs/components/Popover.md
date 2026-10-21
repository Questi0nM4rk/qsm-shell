# Popover

Anchored floating content that flips to the side with the most room and clamps into bounds; it places and reports, and the surface decides open state.
states: open and closed with an opacity and offset settle between them; hover, press and manual triggers arm open and close delays; the shown side follows fit, not the request.
actions: `toggle()` requests open or dismiss by state; `openRequested` and `dismissRequested` report intent, Escape reports dismissal, `hovered` reports the pointer over the anchor or the popover; open state never changes inside.
pointer: hover and press triggers read handlers on the anchor and the popover keeps its own targets; wheel passes through.
keyboard: Escape anywhere in the window reports dismissal while open (a child that needs Escape accepts it in `Keys.onShortcutOverride`); a host key handler on the anchor calls `toggle()`; the content keeps its own tab stops and keys.
screen reader: no role of its own; the anchored content names itself.
size: content size with a fixed anchor gap; placement resamples every frame while settling so anchor and bounds moves are followed.
tokens: space2 and the Motion delay, hoverGrace and easing set; no local colours or measurements.
motion: emphasized entry and exit curve on opacity and offset; reduced motion removes the offset and shortens the opacity duration.
not designed: modal takeover, focus trapping or dismissal policy; use Dialog, Rollout or the host for those.

## UIX audit

Evidence: source-reviewed only. Runtime-exercised: none. Owner-accepted: none. No Workbench session,
capture, key or pointer input was driven. The geometry below is computed from source values; no live
geometry was read, so every layout number is a hypothesis about the rendered unit.

### Purpose and consequence

Places a panel beside its anchor, on the side with room, clamped into bounds, and reports open and
dismiss intent after delays. It finishes the task of a secondary surface a person can reach without
losing it. Failure looks like: the panel off the edge, closing while the pointer crosses to it, or
staying open after the pointer has gone.

### Controls and states

- Public: `anchorItem`, `placement` (top, bottom, left, right), `alignment` (start, center, end), `gap`
  (space2, 8 px), `bounds`, `trigger` (hover, press, manual), `open`, `openDelay` (Motion.large),
  `closeDelay` (Motion.medium), default `content`; signals `openRequested`, `dismissRequested`;
  readonly `side`.
- Implemented: all of the above in Popover.qml.
- Reported facts: `side` only. Hover and keep-open are private (`_wanted`, Popover.qml:253).
- Unit controls (workbench/units/Popover.qml:61-70) reach open and closed and placement top and bottom
  only. Trigger, alignment, left and right, and bounds are not reachable in the window.

### Routes

- Pointer: hover opens through a HoverHandler on the anchor (Popover.qml:220-226) and keeps the popover
  alive through one on the popover itself (229). Press uses a TapHandler on the anchor (231-235).
  Manual leaves all of it to the host.
- Keyboard: Escape only (Popover.qml:269), and only while the popover or a descendant has active focus.
  No key opens a popover. A press trigger has no keyboard equivalent (POP-04).
- Wheel: nothing in the file takes wheel events, so wheel passes through as the record claims. Not run.
- Focus: none of its own. The popover is not focusable, and it neither enters nor returns focus.
- Accessibility: no `Accessible.*` in Popover.qml, Card.qml or Prose.qml. The claim that the anchored
  content names itself has no source support (H2). Criteria belong to a11y-audit, which was not run.

### Sizes, empty, long, failure, cancellation

- Size: content size, `implicitWidth` and `implicitHeight` from `contentHost.childrenRect`
  (Popover.qml:186-187). Unit: anchor 64 by 32 px (space6 times 2, Control `sm` 32), panel Card 190 px
  wide (controlWidth 380 halved).
- Empty: zero-size content gives a zero-size popover with no guard (H3).
- Long: no maximum. When the panel is taller than the bounds, the clamp pins its top to the bounds
  origin (Popover.qml:155-156) and the lower part runs off the bounds with no scroll or elision (POP-09).
- Failure: none defined. Cancellation: leaving before `openDelay` stops the open timer (263), so
  cancellation holds in source.

### Visual roles and motion

- The popover paints nothing; roles come from its content. The unit body is a Card, whose default
  colour is `Style.surface` (Card.qml:9), on a `Style.band` frame. The ladder names a popout as
  `overlay` (POP-11).
- Open: opacity 0 to 1 over `Motion.medium` (260 ms) on `standardEasing`, and an 8 px offset from its
  side on `emphasizedEasing` over the same 260 ms (Popover.qml:190-206).
- Close: opacity on `exitEasing`, offset on `emphasizedEasing`, both 260 ms (197-198, 203-204).
- Reduced motion: `Motion.medium` becomes 100 ms, but the offset still animates (POP-06). The open and
  close delays also shorten (POP-02).

### Pointer geometry

Assumptions, labelled as such: the pointer enters the anchor at its centre, moves on a straight line
perpendicular to the anchor edge, and the anchor origin is its top-left in parent coordinates
(`mapToItem`, Popover.qml:96-97). The width model takes the 8 px gap band as the target width along the
motion axis. No human average is claimed; no trajectory was measured.

- Input shape: the popover's hit shape is its own item bounds, the Card's 190 px width times its
  height (Prose implicit height plus 32 px). It has no expansion, so input equals paint. The anchor's
  input equals its item bounds; in the unit that is the painted 64 by 32 Rectangle.
- Gap: 8 px between anchor and panel (bottom side in the unit). Neither item covers it, and no hit
  test covers it.
- Corridor: the 8 px band. No union or hitbox test governs it. Time does: `closeTimer` starts when both
  hovers are false (Popover.qml:253-266) and runs `closeDelay`.
- Timing: `closeDelay` 260 ms as shipped (Motion.medium), 180 ms by the owner's ruling recorded in
  ux-audit check 3 and held by `Motion.hoverGrace`, which Rollout already uses (Rollout.qml:85).
  `openDelay` 400 ms (Motion.large), 120 ms under reduced motion.
- D: anchor centre to panel top edge, bottom side, unit geometry: 16 + 8 = 24 px.
- W: corridor band: 8 px.
- ID = log2(1 + D/W) = log2(1 + 24/8) = 2.00 bits for the unit's 32 px anchor. A 16 px anchor with the
  same gap gives log2(3) = 1.58 bits. The anchor's own reach belongs to the host and is not modelled.
- Landing tolerance: the 8 px band, bounded in time by `closeDelay`: 260 ms as shipped, 180 ms by ruling.
- Neighbouring interference: another anchor inside the 8 px band could take hover from the corridor (H5).
- Diagonal exit: a pointer that leaves an anchor corner towards a panel outside its span crosses the
  same band. Only the timer covers it.

### Findings

Source-backed defects. Each cites file and line. Shared is true only where the fix touches a shared path.

Fixed (source-reviewed, load-checked; runtime-exercised none, owner-accepted none): POP-01, POP-03,
POP-04, POP-05, POP-06, POP-07, POP-10, POP-11. Their entries below describe the state before the fix.
POP-03: the Shortcut outranks a focused child's key handler, so the "a focused child that consumes
Escape still does" check was not run and holds only for a child that accepts `Keys.onShortcutOverride`.
POP-10: the unit now reaches trigger, alignment, left and right, and a tight anchor that forces the
flip, and answers `toggle` from the anchor's Return and Space.

- POP-01 (fixed, minor, shared false): Popover.qml:54 closes after `Motion.medium` (260 ms). The owner's
  keep-open ruling is 180 ms, which is `Motion.hoverGrace`. Person sees: a hover popover lingers about
  80 ms longer after the pointer leaves. Fix: `closeDelay: Motion.hoverGrace`.
- POP-02 (minor, shared true): Popover.qml:53-54 use duration tokens for timeouts. Motion.qml:58 and :60
  shorten `medium` and `large` under reduced motion, while Motion.qml:113-118 says timeouts must not
  shorten. Person sees: with reduced motion on, a hover popover opens after 120 ms instead of 400 ms,
  and a passing pointer can flicker it. Fix: close via POP-01. Open needs a token that does not shorten,
  which is a Style and tokens change.
- POP-03 (fixed, major, shared false): Popover.qml:269 is `Keys.onEscapePressed` on a non-focusable root, so it
  fires only while focus is inside the content. A keyboard user who opens the popover from a focused
  trigger presses Escape and nothing closes. Fix: a `Shortcut { sequence: "Escape"; enabled: root.open;
  context: Qt.WindowShortcut; onActivated: root.dismissRequested() }`, with a check that a focused
  child that consumes Escape still does.
- POP-04 (fixed, major, shared false): Popover.qml:231-235 opens a press trigger from the pointer only, and
  `actions` is empty. Person sees: a keyboard user cannot open a press-triggered popover. Fix: a listed
  `toggle()` function that the TapHandler and the host's key handler on the anchor both call.
- POP-05 (fixed, minor, shared false): Popover.qml:253 keeps hover private. The component contract (Definition
  of done, item 4) requires hover and keep-open to be reported. Person sees: a host must re-derive
  whether the pointer is over the popover. Fix: a public `hovered` bound to `_wanted`.
- POP-06 (fixed, minor, shared false): Popover.qml:193-199 animates the 8 px offset without a reduced-motion
  check. AGENTS.md says a one-shot position animation is removed under reduced motion. Person sees: a
  slide still plays with reduced motion on. Fix: no offset when `Style.reducedMotion`.
- POP-07 (fixed, minor, shared false): the close offset uses `emphasizedEasing` (Popover.qml:197-198), while
  the close opacity uses `exitEasing` (204). Motion.qml:124-125 says an enter curve on an exit makes it
  hesitate. Person sees: the offset and fade of one close follow two curves. Fix: choose
  `exitEasing` for both on close. See SC-2.
- POP-08 (minor, shared true): exit uses `Motion.medium`, the same 260 ms as entry (Popover.qml:197-198,
  203). review-animations standard 4 puts exit at about 80 percent of entry. Fix needs a Motion token for
  exit; a literal 0.8 breaks the every-number-from-Style-or-Motion rule.
- POP-09 (minor, shared false): Popover.qml:155-156 and 186-187 set no maximum. A panel taller than its
  bounds is pinned to the bounds top and runs off the bottom with no scroll or elision. Fix: a
  bounds-derived `maxHeight` the content scrolls within.
- POP-10 (fixed, major, shared false): workbench/units/Popover.qml:61-70 expose only open and placement top and
  bottom, and the unit never sets `trigger`, so it stays `manual` (default Popover.qml:49). Person sees:
  in the owner's window, hover, press, the timers, the left and right flip (Popover.qml:70-77) and the
  alignment are unreachable. Fix: add trigger, alignment and left and right options to the unit.
- POP-11 (fixed, minor, shared false): workbench/units/Popover.qml:47-50 gives the popout body a Card, whose
  default is `Style.surface` (Card.qml:9). The ladder names a popout `overlay`. Person sees: the popout
  reads as a card on the band, not as a layer above a card. Fix: the overlay role for the body.

Source conflicts, for the owner to rule:

- SC-1: Popover.qml:51-53 argues that a hover surface must not open instantly, and sets 400 ms. ux-audit
  check 3 says a surface that opens on hover opens on entry, a tooltip being the exception. Whether this
  popover is a tooltip-like surface is the owner's call.
- SC-2: Motion.qml:124-125 names exit as `exitEasing` (InCubic). review-animations standard 3 names an
  ease-out or strong custom curve for exit. POP-07 follows the first for opacity and the second for offset.
- SC-3: the record's first paragraph says hover, press and manual triggers arm open and close delays.
  Source says only hover does (Popover.qml:255-257). The existing record is left as written.

Proposals (taste, for the owner to look at in a live window):

- PR-1: a scale from the anchor side, as review-animations standard 5 describes, in place of the 8 px
  slide (Popover.qml:193-199).
- PR-2: a toggle and a Shortcut together (POP-03, POP-04) so every route calls the same function.
- PR-3: Caelestia's Menu.qml follows its anchor with its own TransformWatcher (Menu.qml:60 onward), not a
  per-frame sample. Popover.qml:81-90 samples on purpose. Keep the sample and record the choice. Caelestia
  has no Popover sibling; its popout and drawer files read (bar/popouts/Wrapper.qml,
  drawers/Interactions.qml) show no delay values.
- The word "held" at Popover.qml:27 is already tracked in docs/BACKLOG.md under "Left standing by the
  owner", so it is not filed again.

Hypotheses (suspected, not measured):

- H1: `visible: opacity > 0` (Popover.qml:189) may drop focus held inside the content on hide, and
  nothing returns it to the trigger.
- H2: the record's claim that the content names itself is unsupported by source (see Accessibility).
- H3: empty content gives a zero-size popover with no guard.
- H4: hover triggers never fire from touch. The press trigger does, through TapHandler.
- H5: an adjacent anchor inside the 8 px band could steal hover.

Needs human trial (a live hand, not run):

- Hover: enter the anchor, hold still, and time the open at about 400 ms. Leave the anchor and cross the
  gap to the panel. Pass: the panel stays. Leave both and time the close, 260 ms as shipped.
- Keyboard: focus a trigger, open the popover from it, press Escape. Pass: it closes. Fails today (POP-03).
- Reduced motion on: the offset must be gone and the delays unchanged. Fails today (POP-02, POP-06).
- Touch: a press trigger opens and closes by tap.

Not examined: runtime behaviour of any route; captures; the wheel path at runtime; outside-click
dismissal, which is the surface's policy; the design-source tooltip delay (ui-design was not loaded for
this pass); accessibility criteria (a11y-audit was not run for this surface).
