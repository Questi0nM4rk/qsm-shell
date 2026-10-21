# ActionTile

A stacked icon-over-label tile for equally-weighted session choices laid out as a column or grid; the host owns selected and armed, and armed outranks selected because what happens next matters more than what is picked.
states: rest, hover, press, focus, disabled, selected and armed; armed is a solid `armedColor` fill and selected a solid `accent` fill (primary on the session surface), both with `textOnPrimary` glyph and label (spec 08), not a tint, focus rings the body, disabled dims every painted role through Style.disabled rather than composite opacity.
actions: pointer click, Space, Return, Enter and the actions entry call activate() and emit activated; selected and armed never change inside the component and disabled activation does nothing.
pointer: the full tile is the target and reports a hand; wheel does nothing and propagates.
keyboard: Tab reach, click takes focus, and Space/Return/Enter share the activate() route.
screen reader: Accessible.Button named shownLabel, so the armed confirmLabel is what is announced while armed.
size: fixed footprint buttonWidth/buttonHeight from the tile scale so a set lines up; icon, spacing and radius from tokens, content never grows the tile.
tokens: tileWidth, tileHeight, radiusMd, iconLg, space scale, surface ladder, accent, danger, text roles, Style.disabled, Motion, StateLayer and Surface; no local colors or measurements.
motion: StateLayer hover and press response plus color settling; reduced motion shortens the duration, never invents another state.
not designed: confirmation policy, product consequence, asynchronous progress and menus; the host owns what armed means and what activation does.
review: choose a concrete session action with the owner; glyph, verb and confirmation name that same consequence. Power-off is one possible example, not the type's identity. The current fixture is not owner-accepted.

## UIX audit

Evidence: source-reviewed only. No runtime, no capture, no owner acceptance. Line numbers refer to `qml/QsmShell/Components/ActionTile.qml` unless named.

### Purpose and consequence

The tile is one of a column or grid of equal session choices; the host decides what armed and selected mean and what activation does. The consequence that matters is the destructive one: a Shutdown tile in a session surface is reached by pointer and by keyboard, and one activation must not power off a machine.

### Expected controls and states

| Control | Valid values | Implemented |
| --- | --- | --- |
| selected | true, false | yes, host-owned, line 31 |
| armed | true, false | yes, host-owned, line 32; armed outranks selected (line 78) |
| danger | true, false | yes, resting glyph and label in `armedColor` (line 57, 89) |
| enabled | true, false | yes, disabled dims colour through `Style.disabled` (line 61) |
| confirmLabel | text | yes, shown while armed, falls back to label (line 62) |
| size | a preset name | no. Only `buttonWidth`/`buttonHeight` raw numbers (lines 39-40) |

States: rest and selected and armed and danger and disabled are painted. Hover, press and focus are declared in StateLayer; see defects 1, 2 and 3.

### Routes

- Pointer: full tile is the target (StateLayer `anchors.fill`, line 95); hand cursor (StateLayer HoverHandler); click fires `activate()` through StateLayer `onClicked` (line 99-102), which also takes focus.
- Keyboard: `focusPolicy: Qt.StrongFocus` (line 50); Space, Return and Enter call `activate()` (lines 110-112). Defect 6.
- Wheel: no handler. Propagates (source only).
- Focus ring: StateLayer ring, 2 px stroke at `Style.spaceTight` outside the body, outer radius `radiusMd + 4` (StateLayer). Suppressed after a pointer press until focus is lost (StateLayer `_pointerFocus`).
- Accessibility: `Accessible.Button` named `shownLabel` (lines 53-54). Selected, armed and disabled are not exposed as states. Handed to a11y-audit.

### Sizes, empty, long, failure, cancellation

- Size: 96 x 72 (`Style.tileWidth`/`tileHeight` from `Tokens.geometryTileWidth/Height`). Icon `iconLg` 24, label `typeSm` 12, gap `space1` 4: content height 40 in 72, 16 px above and below.
- Empty label: no guard. `shownLabel` can be empty (line 62) and the tile then has an icon only with no accessible name.
- Long label: defect 5.
- Failure: none modelled. A failed host action has no tile state.
- Cancellation: none in the component. Disarm on exit or on deselect is the host's.

### Visual roles and palette pairs

Computed from `tokens/deep-night.json` with WCAG relative luminance, source colours, rendered pixels not sampled:

| Pair | Ratio | Source |
| --- | --- | --- |
| text `#f0ecf5` on surface `#3b3145` (icon, rest) | 10.53 | line 84 |
| textMuted `#c5bad1` on surface (label, rest) | 6.61 | line 89 |
| danger `#f5aeb7` on surface (danger rest) | 6.05 | line 57 |
| textOnPrimary `#271e30` on accent `#d9b4ea` (selected) | 8.87 | line 57 |
| textOnPrimary on armedColor `#f5aeb7` (armed) | 8.84 | line 57 |
| accent ring on band `#271e30` (ring against host) | 8.87 | StateLayer ring |
| accent ring on overlay `#4c4357` | 5.19 | StateLayer ring |
| surface `#3b3145` on band (resting body on ladder) | 1.30 | line 78 |
| disabled (opacityDisabled 0.35) | exempt | Tokens.qml:69 |

The resting body is 1.30:1 against band, the ladder's step.

### Motion and reduced motion

- Body colour: `Surface` `Behavior on color` at `Motion.micro` 130 ms (Surface.qml, end of file).
- Size: StateLayer `response` `Behavior` (duration `press` 80 ms if pressed, else `micro` 130 ms). Hover target 1.08 (`Motion.hoverScale`, Motion.qml:46 from `Tokens.motionHoverScale`). Press target `Motion.pressScale` (defect 1, fixed).
- Reduced motion: `Motion.micro` 60 ms and `press` 40 ms under `Style.reducedMotion`. The 1.08 hover scale is not affected by reduced motion (defect 4).
- Icon and label colour: `Behavior on color` at `Motion.micro`, same curve as the body (defect 2, fixed).

### Pointer geometry

Input shape and painted size are the same: a 96 x 72 rectangle at rest, the StateLayer and the Surface both fill the control. On hover the scale binding on the control (`StateLayer` `target: parent`) grows both to 103.7 x 77.8, so the hit area grows with the paint.

Model, stated: W is the tile's painted extent along the approach axis; the column is vertical, so W = 72 px vertically (96 px horizontally). D is centre to centre. Spacing is the host's: `space2` 8 px between tiles, and 16 px before Shutdown (a `space4 - space2` extra top margin, so 8 + 8 = 16). Origin assumption: each tile's centre is its origin; the label origin is the Column's centre (line 82). No human average is claimed.

| Move | D (px) | W (px) | ID = log2(1 + D/W) bits |
| --- | --- | --- | --- |
| Lock to Logout (adjacent) | 80 | 72 | 1.08 |
| Reboot to Shutdown | 88 | 72 | 1.15 |
| Lock to Shutdown (a host's five tiles) | 328 | 72 | 2.47 |

Landing tolerance: plus or minus 36 px vertically at rest, plus or minus 38.9 px while hovered. Neighbouring interference: the dead gap is 8 px (16 before Shutdown). Hover growth adds 2.88 px per side, so a hovered tile reaches 5.12 px into an 8 px gap, no overlap. A keyboard focus ring adds 4 px outside a tile (Style.spaceTight x 2). A focused tile with a hovered neighbour uses 2.88 + 4 = 6.88 px of the 8 px gap, leaving 1.12 px. On the way from Lock to Shutdown the pointer enters Logout, Hibernate and Reboot, and each entry calls the host's `select(index)` (`onEntered`), so the primary fill follows the pointer across three tiles, one of them destructive.

Popup corridor: not applicable (the tile is not a popup).

### Findings: source-backed defects

1. **major. Fixed (source-reviewed, load-checked; not owner-accepted).** The Surface now binds `hovered` and `pressed` from the StateLayer (colour lift) and the StateLayer sets `pressScale: Motion.pressScale`. Was: No hover colour, no press colour. `ActionTile.qml:75-79`: the body `Surface` does not bind `hovered` or `pressed`, and `StateLayer` keeps the default `pressScale: 1` (not set here), so `response` returns to 1.0 on press. What a person sees: hover only grows the tile; a click shows no change beyond the growth going away, so the press looks like rest. The owner's rule, `AGENTS.md` "Hover grows slightly AND changes colour", is not met. Fix: bind `hovered: root.hovered` on the Surface and set `pressScale` (0.95 to 0.98 is the animate recipe; 0.96 is inside it) on the StateLayer. Both lines are in ActionTile.qml. shared=false.
2. **major. Fixed (source-reviewed, load-checked; not owner-accepted).** The SvgIcon and the Prose carry a `Behavior on color` at `Motion.micro` with `Motion.standardEasing`, the body's own curve. Was: Glyph and label colour snap while the body fades. `ActionTile.qml:84` (SvgIcon colour) and `:89` (Prose colour) have no `Behavior`; the body fades over 130 ms (Surface `Behavior on color`). When a tile is selected the label jumps to `textOnPrimary` `#271e30` while the body is still near `#3b3145`: 1.30:1 for the start of the fade (band to surface ratio). What a person sees: the text blanks for about 130 ms on each selection change. Fix: a `Behavior on color` on the Prose and on the SvgIcon in ActionTile.qml, using `Motion.micro` and `Motion.standardEasing`, or a single colour transition for all three. shared=false. Verdict belongs to review-animations (see below).
3. **major.** Keyboard focus and selection can disagree. `ActionTile.qml:110-112` accept Space, Return and Enter and fire the focused tile. A host that moves `selectedIndex` with Up and Down without moving focus leaves the ring on one tile and the fill on another, and Enter fires the ring tile. The component doc (line 17) says the keyboard has to fire the selected one. Fix: remove the three Keys handlers so the keys reach the host, which fires `activate(selectedIndex)`; or the host moves focus with selection. Touches the host, so shared=true.
4. **minor.** Keyboard-initiated selection animates. A selection change from an arrow key fades the body for 130 ms (Surface `Behavior on color`, reached through `selected` at line 78). The standard in review-animations, item 2, says keyboard-initiated changes get no animation. Fix: the fade belongs to Surface, which is shared: remove the colour `Behavior` for selection, or let the host set selection without it. shared=true.
5. **minor.** Reduced motion keeps the hover growth. `Motion.hoverScale` (Motion.qml:46) is a plain token; `Style.reducedMotion` shortens the durations only. Standard 8 says reduced motion drops movement and keeps opacity and colour. Fix: `Motion.hoverScale` returns 1.0 under `Style.reducedMotion`, in Motion.qml and the StateLayer that reads it. shared=true.
6. **minor. Fixed (source-reviewed, load-checked; not owner-accepted).** The Prose width is `min(implicitWidth, buttonWidth - 2 * space1)`, so ElideRight applies. Was: Label overflows the tile when long. `ActionTile.qml:85-91`: the Prose has no width, so `elide: Text.ElideRight` (set in Prose) has nothing to elide against and a long label extends past the 96 px body on both sides (Column centred). Short host labels fit, so this is latent. Fix: bind the Prose width to the tile's inner width (`width: root.buttonWidth - 2 * Style.space1`). shared=false.
7. **minor.** The doc says "fixed footprint buttonWidth/buttonHeight from the tile scale". There is no tile scale: `buttonWidth`/`buttonHeight` default to raw `Style.tileWidth`/`tileHeight` (lines 39-40), icon, label and gap are constants, and `Style.size("ActionTile", ...)` is not used. The component law "one scale per instance" is not met. Fix: a `size` preset in `tokens/deep-night.json` `sizes.ActionTile`, `Style.size` in the component, and icon, label and gap through `Style.iconNear`, `Style.textNear`, `Style.rhythm`. shared=true (tokens and Style).

### Redesign proposals (taste, not defects)

- Label role. `ActionTile.qml:85-88` uses `role: "metadata"` (weight regular, muted colour) and then overrides `pixelSize` and `color`. The role should decide the size and weight. Make it `role: "label"` and drop the pixelSize line, unless the owner wants the fine-print weight. Owner decision: visual weight.
- Press shape. caelestia `components/controls/ButtonBase.qml` changes the radius on press (`pressedRadius`, `radiusMorph`). A radius change could carry the press better than colour alone on a tile.
- Armed without `confirmLabel`. Armed and selected differ only in hue (`armedColor` `#f5aeb7` vs `accent` `#d9b4ea`, both pastel). A host that sets `confirmLabel` is fine; one that leaves it empty relies on hue alone.
- Ring crowding. A focused tile next to a hovered tile leaves 1.12 px of an 8 px gap. Consider a wider `space2` for the grid, or the ring at spaceTight outside only.
- Hover scale on a 96 px tile is 3.84 px per side. Taste: keep, or reduce to 1.04 for a calmer shell.

### Hypotheses

- Held Return or Space on an armed tile may fire `activate()` on each key auto-repeat (`ActionTile.qml:110-112`, no `isAutoRepeat` check). If Qt delivers auto-repeat to `onReturnPressed`, a long hold of Return on Shutdown arms, then confirms in one hold. Not run. Check: hold Return on an armed tile in a live window.
- Armed state is not announced to a screen reader. `Accessible.name` changes to `confirmLabel` (line 54), but no state or description is set. Handed to a11y-audit.
- The tile's Accessible state for disabled is not set explicitly (lines 53-54). Handed to a11y-audit.

### Not examined

- Runtime: no capture, no live window, no pointer or key trace, no frame timing. Hover, press, focus ring and selection were read from source only.
- Motion curve: `Motion.standardEasing`'s value was not read; the easing check (standard 3) is incomplete.
- Light theme and other scales: only deep-night tokens exist in `tokens/deep-night.json`.
- Wheel: source-read only (no handler), not driven.
- Host labels: fit was reasoned from the strings, not measured.

### Motion verdict (review-animations)

Block. Standards 2 (keyboard-initiated selection animates, defect 4), 5 (press has no physical response, defect 1), 8 (reduced motion keeps movement, defect 5) and 3 (text blanks during the body fade, defect 2) fail on source. Feel cannot be judged from code: check by raising `Motion.micro` to 2 to 5 times in a live window, then pressing a tile, and by a frame-by-frame capture of one selection change.

### Before and after

| Before | After | Why |
| --- | --- | --- |
| hover grows, no colour change (`Surface` without `hovered`) | `hovered: root.hovered` on the body, colour lift 0.4 | owner rule: growth and colour together |
| press returns to 1.0 with no colour | press scales to 0.96 on StateLayer (`pressScale`) | the press needs an answer the eye can see |
| label and glyph colour snap, body fades over 130 ms | `Behavior on color` on Prose and SvgIcon at `Motion.micro` | the text stays readable while the body changes |
| Space, Return, Enter fire the focused tile | keys reach the host, which fires the selected tile | one answer to "what fires" |
| hover growth under reduced motion | no growth under reduced motion, colour kept | standard 8: drop movement, keep colour |
| `buttonWidth` 96 raw | `Style.size("ActionTile", size)` with `md` = 96 | one scale per instance |
