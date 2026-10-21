# ArmedAction

A non-visual confirm-then-fire helper for destructive commands; the host owns the armed flag display and the action's consequence.
states: disarmed rest and armed intent; arming expires after `timeout` (3000 by default) and reports `disarmed` (a confirmed fire does not); with `destructive` false every trigger fires at once.
actions: `trigger()` arms a destructive command or fires when already armed, `disarm()` abandons the intent; pointer, keyboard and programmatic routes share them.
pointer: none; it paints nothing, takes no pointer and claims no events.
keyboard: none; the surface holding it routes keys to `trigger()` and `disarm()`.
screen reader: none; the visible control it guards supplies the accessible name and the armed announcement.
size: none; a QtObject with no footprint, no slots and no natural size.
tokens: none; no Style, Motion or colour roles of its own.
motion: none; arming is state, and any visible countdown belongs to the host.
not designed: the confirm control itself, policy, product consequence or persistence; use ActionTile, Capsule or the host for those.

## UIX audit

Evidence: source-reviewed; the fixes are load-checked by one offscreen capture of `armed-action`
(exit 0, no QML error). No other runtime was exercised. Owner-accepted: none. Channels: 1 capture
load only; 2 live geometry none; 3 design source
`tokens/deep-night.json` and `qml/QsmShell/Style/Style.qml` read; no `design/MASTER.md` read.

### Purpose and consequence

Finishes one task: a destructive command runs only after a second deliberate trigger made inside a
window. The first trigger changes no data. A non-destructive command fires on the first trigger.

### Controls and states

| Item | Implemented | Where |
| --- | --- | --- |
| `destructive` (default true) | yes; false makes `trigger()` fire at once | ArmedAction.qml:25, :42 |
| `timeout` (default 3000 ms) | yes; restarts on arm, expiry calls `disarm()` | :28, :69-70 |
| `armed` (read-only) | yes; bound to `state.armed` | :30, :63-64 |
| `confirmLabel` | removed; hosts own the armed wording | n/a |
| disarmed to armed | yes | :47-48 |
| armed to fired | yes; clears armed and stops the timer, emits `fired` and not `disarmed` | :41-47 |
| armed to disarmed (timeout, `disarm()`) | yes | :54-59 |
| destructive changed while armed | disarms | :26 |
| extend or pause the window | not offered | n/a |

### Routes

- Pointer: none in this component. A tile click reaches `ActionTile` `StateLayer.onClicked`, then
  `activate()`, then the host's `trigger()`; a cell click calls `trigger()` directly.
- Leave: a consumer calls `disarm()`, on hover loss or on exit.
- Keyboard: none in the component. A host maps Return, Enter and Space to `activate`
  (two presses arm then fire), Up and Down to selection, which disarms the old tile, and Escape to
  closing without disarming first (harmless, see P1).
  The unit's `keys` map (Enter, Escape) is a harness call, not a Qt key route.
- Wheel: none. Focus: none in the component; the ring belongs to `ActionTile` through `StateLayer`.
- Accessibility: none in the component. `ActionTile` sets `Accessible.name` to `shownLabel`, which is
  the bare host wording while armed (H3).

### Sizes, content, failure, cancellation

- Size: none; a `QtObject` with no footprint. Consumer tile: library default 96 by 72 px from
  `tokens/deep-night.json` lines 121-122 (`tileWidth`, `tileHeight`).
- Empty and long content: none in the component; the label belongs to the host.
- Cancellation: timer expiry (:70), host leave, selection change. A non-destructive trigger has no
  cancellation at all.
- Failure: an exception in a `fired` handler is not examined.

### Visual roles and palette pairs

None in the component. The consumer's armed fill is `armedColor`, default `Style.danger`, with
`Style.textOnPrimary` content (`ActionTile.qml`, `_baseColor`). The pair's contrast is not measured:
no capture exists (ui-audit pass 4 is open).

### Motion

None in the component; arming is state. Reduced motion is not applicable here. `ActionTile`
transitions were not read for this record.

### Pointer geometry

Not a popup: no trigger-to-panel corridor. Assumptions, not measurements: the pointer enters the tile
from the neighbouring tile's edge; the label is centred under the glyph (`ActionTile.qml`, the
content column); label weight is the `metadata` role, not measured. No human average is claimed.

- Input shape: `ArmedAction` has none. The consumer's target is the `ActionTile` `StateLayer`
  anchored to the whole tile, so the hit area equals the painted tile, 96 by 72 px.
- Width model: W is the tile's extent along the approach axis, 72 px for vertical moves between
  stacked tiles. ID = log2(1 + D/W), Shannon form.
- Adjacent tile: D = 72 + space2 (8) = 80 px, so ID = log2(1 + 80/72) = 1.08 bits.
- Shutdown tile after an adjacent tile: D = 72 + 8 + 8 (`Layout.topMargin` = space4 minus space2 = 8)
  = 88 px, so ID = log2(1 + 88/72) = 1.15 bits.
- Confirm (second trigger on the same tile): D = 0, so ID = 0 bits. The model does not measure this;
  the cost is holding the pointer inside the tile for up to 3000 ms.
- Landing tolerance: 0 px beyond the tile edge. Leaving fires `exited` and the host disarms: no
  hysteresis.
- Neighbour interference: the 8 px gap. Drifting across it disarms the armed tile and selects the
  neighbour (a host's `onEntered` selects, `onSelectedChanged` disarms).
- Timing: 3000 ms is a designed value (:28), unmeasured against people.

### Findings

Proposals (design, not defects):

- P1: a host that closes its surface on Escape leaves an armed tile armed until its timer runs out.
  Calling `disarm()` before closing would end the intent where the user ended the surface. Host change.
- P2: The unit cannot show leave-to-disarm because it has no pointer route. Give it an exit hook in
  the harness, not in the component.

Hypotheses (unmeasured):

- H1: `timeout: 0` makes a destructive tile unconfirmable. The timer fires on the next loop, before a
  second click, so each click re-arms. No caller sets 0 and nothing validates it. Unrun.
- H2: a 3000 ms window the user cannot extend may meet WCAG 2.2.1 (Timing Adjustable, A). Whether the
  window counts as a time limit is for a11y-conformance; not decided here.
- H3: a host that names the armed tile with the bare "Confirm" gives a screen reader no object name. This is `ActionTile`'s naming, not this component's; a11y-audit.
- H4: the armed change is not announced: no live region exists in the source. a11y-audit.

Not examined: any runtime route, the armed tile's contrast, reduced motion, the `Rollout` corridor, a host's own tile sizes, and a `fired` handler that throws. No
caelestia sibling exists: a grep of `~/Clonned/caelestia/repo/components/controls/` for armed or
confirm found nothing.
