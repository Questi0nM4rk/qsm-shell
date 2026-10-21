# Segmented

## Production record

`Segmented` is a small, horizontal one-of-N control for panel tabs and value
choices. The host owns `currentIndex`; `selected(index)` reports intent and the
host answers it. `options` accepts labels or objects with `label`, `icon`,
`badge`, and `disabled`.

Settings are `options`, `currentIndex`, `enabled`, the free-set `size`
preset (`sm`, `md`, `lg`, or a consumer-defined name); `barHeight` remains
the direct sizing escape hatch. Segments are equal-width, fixed-natural-width,
single-line, and elide long labels. Empty icon and badge slots cost no space.

`tabNavigation` opts into an owner's Tab/Shift+Tab selection contract while
focus is inside this one group; the default stays the conventional single tab
stop. `wrapNavigation` defaults to true; a group whose ends are visible
landmarks sets it false. Tab, Backtab, arrows and the actions share one
`step` route, unavailable options are skipped, modified keys are left alone,
and focus stays in the group. Nothing here reaches a sibling editor's typing.
This is an explicit departure from the usual Tab-leaves-a-tablist pattern,
asked for by one consumer, not a new default for everyone. Caelestia's native
TabBar ownership is reused, not its separate wheel handling or indicator.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | Choose one shell section without leaving the group | Owner's panel task; auxiliary transient surface | T.TabBar | Keyboard section switching |
| interaction | Opt-in Tab/Backtab reuses `step` and skips unavailable options | Owner contract; conventional arrows retained | select/step | Forward, reverse, endpoints, unavailable |
| hierarchy/token | The existing quiet equal-cell group and focus ring, unchanged | No visual redesign was asked for | Style size/text/state scales | Owner live review |
| responsive/state | Fixed natural size, elided labels, no movement when all options are unavailable | Component laws | Style.controlWidth, StateLayer | Empty/long/disabled unit cases |
| polish | No new motion or colour | Accepted direction | Style/Motion | Owner live review |

Pointer selection, Space/Enter activation, horizontal arrows, Home/End, and
the `Previous`, `Next`, `First`, and `Last` actions use the same selection
route. Arrows wrap and skip disabled options; Home/End choose the first/last
enabled option, including when an endpoint is disabled. RTL follows the visual
arrow direction. Focus is one native tab stop into the selected/first item;
the template provides tab semantics and screen-reader selected/disabled state.

The unit must make first, middle, last and all-disabled cases reachable,
including a selected option becoming unavailable. A middle-only switch does
not represent per-option availability. Sample labels and optional glyphs name
one coherent choice; the owner accepts the fixture and interaction before the
next type starts.

The bar takes the Control presets: `xs` (24), `sm` (32), `md` (40) and `lg` (48). One scale from
the bar height scales text, glyphs, spacing, and insets through the Style
helpers; radius, focus gap, and borders do not scale. Rest, hover, pressed,
focused, selected, and disabled states are explicit. Disabled roles are dimmed
by colour, never composite opacity. Selection is accent identity over one
outer Surface body.

Events are the `selected(index)` intent signal and the inherited template
pointer/focus/accessibility events. A small visible set is required; this type
is not designed for vertical orientation, scrolling many options, wrapping
labels, or a gliding cross-cell indicator (the latter remains an owner
question).

Sources: Qt `TabBar`/`TabButton` template semantics; WAI-ARIA tabs keyboard
pattern; Radix ToggleGroup; Fluent fixed tab sets; shadcn size/disabled/RTL
group conventions; Caelestia `Tabs.qml`; `docs/adr/0001-controls-on-templates.md`.

## UIX audit

Fix status: defects 2, 3, 4 and 5 are fixed (source-reviewed, load-checked), never owner-accepted;
the findings below describe the state before those fixes. Defect 3 trade-off for the owner:
`step()` reads the old `currentIndex` until the host answers, so a host that answers late
makes a fast key repeat step from a stale index. Defect 5 leaves the badge's 10 px text fixed:
scaling it needs a `Badge` change (shared).

Evidence: source-reviewed only. Runtime-exercised: none. Owner-accepted: none recorded by this
audit. Contrast and geometry figures are computed from `tokens/deep-night.json` and the `Style`,
`Motion` and `Badge` formulas; they are not sampled from a render, and blending or layer effects
can move them. Channels not available: capture, live geometry, the workbench unit, a second theme,
a screen reader.

### Purpose and consequence

Choose one of N visible options, by pointer or keyboard, and let the host act on the choice: a
panel section switch or a power profile. It is a
glanceable selector; the thumb marks the current choice.

### Controls and states

| Item | Status |
| --- | --- |
| `options` (string, or `label`, `icon`, `name`, `badge`, `disabled`) | implemented; empty options render an empty track, no fixture |
| `currentIndex` (host-owned) | implemented, but `select()` writes it first (defect 3) |
| `enabled`, `size` (`sm` 32, `md` 40, `lg` 52 via `Style.size`), `barHeight` | implemented |
| `tabNavigation`, `wrapNavigation` | implemented; `tabNavigation` with `wrapNavigation: false` is a trap (defect 1) |
| `selected(index)` | implemented, emitted after the local write |
| actions `previous`, `next`, `first`, `last` | implemented, same route as keys |
| rest, hover, pressed, focus, disabled | all five present through `StateLayer` and `tone` |
| selected, selected-and-unavailable | selected present; unavailable pill does not dim (defect 2) |
| wheel | no route; nothing answers it, and the record says so |
| loading, error, cancel | not applicable: no input state; a drag off a segment cancels by the tap threshold, not runtime-checked |

Unit controls (`workbench/units/Segmented.qml`) reach first, middle, last and all disabled, and a
selected option becoming unavailable (`unavailable: first` with the default `Overview` selected).
`middle-option` duplicates `unavailable: middle` for the same option. Missing fixtures: empty
options, long labels, icon-only, badge.

### Routes

- Pointer: click on a segment calls `select()` (`Segmented.qml` 92-98, 238). Hover lifts the
  unselected segment (`hoverScale` `Motion.capsuleHoverScale`, lines 298-307). Track margins and
  the gaps between segments do not respond. Press changes colour only (`pressScale` 1).
- Keyboard: the bar takes the single tab stop (`activeFocusOnTab`, line 45). Left and Right step
  (mirrored under RTL, 133-136); Home and End select the first and last enabled option (137-142).
  Tab and Backtab step only with `tabNavigation` (124-130). Space and Enter reach `onClicked` only
  on a segment that holds focus by mouse; the bar itself handles neither (hypothesis H5).
- Focus: the ring sits outside the selected segment, and only while the bar has focus (313). A
  segment with no selection gets no ring (defect 4).
- Accessibility: bar `PageTabList`, segments `PageTab` with `Accessible.selected` (49, 234-237).
  Segment names come from the label or `option.name`. The bar has no default name; both consumers
  set one (`Panel sections`, `Power profile`).

### Sizes, content, failure

Width model: track width `W` = `Style.controlWidth` 380, `n` options, `segW = (W - 2 pad - gap (n-1)) / n`.
Preset values use `s = barHeight / 40`, `pad = rhythm(8 s)`, `gap = rhythm(4 s)`,
`text = textNear(12 s)`, `icon = iconNear(16 s)`.

| Preset | Track | Inset `pad` | Gap | Item height | Label | Glyph | `segW` at n=3 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| sm | 32 | 8 | 4 | 16 | 10 px | 12 px | 118.67 |
| md | 40 | 8 | 4 | 24 | 12 px | 16 px | 118.67 |
| lg | 52 | 12 | 4 | 28 | 14 px | 20 px | 116.00 |

- Long content: the label is single-line and elides (`Prose` ElideRight, `maximumLineCount` 1,
  lines 279-281). With 6 options at 380 px, `segW` is 57 px and labels such as `Overview` at 12 px
  will elide. No fixture shows it.
- Empty: no options means an empty track with no thumb (`visible` needs `currentIndex >= 0`,
  line 165). Nothing says the group is empty.
- Failure: a host that refuses a choice leaves the thumb on the clicked option (defect 3).
- Badge: the chip is `rhythm(badgeHeight * s)` high (12, 16, 20 at sm, md, lg) with `Badge`'s fixed 10 px
  text (defect 5).

### Visual roles and palette pairs (computed from tokens)

| Pair | Ratio | Verdict |
| --- | --- | --- |
| muted label on track (`textMuted` on `surface`) | 6.61 | passes 4.5 |
| hovered label on track (`text` on `surface`) | 10.53 | passes |
| selected label on thumb (`accent` on accent 12 % over `surface`) | 5.25 | passes 4.5 at 12 px |
| selected thumb against track | 1.30 | fails 3:1 for a state indicator (defect 6) |
| selected label against unselected label (`accent` vs `textMuted`) | 1.03 | selection rests on the thumb |
| focus ring (`accent`) against track | 6.82 | passes 3:1 |
| neutral badge text on its tint | 6.56 | passes 4.5 at 10 px |
| selected badge text on its tint | 5.18 | passes 4.5 at 10 px |
| disabled selected label on thumb | 1.21 | defect 2 |
| disabled unselected label on track | 1.55 | inactive, exempt; see proposals |

Motion: thumb glide `Behavior on x`, `Motion.fast` 180 ms, `Motion.standardEasing` (OutCubic),
disabled under `Style.reducedMotion` so it snaps (`Segmented.qml` 185-188). Hover scale and colour
use `Motion.micro` 130 ms through `StateLayer` (`response`, lines 126-131); that behaviour does not
check `reducedMotion` (hypothesis H3 covers the reduced form).

### Pointer geometry

- Input shape: each `TabButton` rectangle, `segW` by item height. The painted item and the thumb
  are the same rectangle, so input and painted size match. The track margin (`pad`) and the gaps
  between segments take no input.
- Hover growth: `capsuleHoverScale` 1.04 scales the hit rectangle too, about 2.4 px a side at md
  and lg. It does not reach a neighbour across the 4 px gap.
- Label origin (assumption): centre of the segment, `RowLayout` `centerIn` (line 261). Weight
  (assumption): `Style.weightMedium`, `Font.Medium`.
- Size against the 24 px floor (WCAG 2.5.8): md 24 px passes exactly; lg 28 px passes; sm 16 px
  fails by size and passes only through the spacing exception. A 24 px circle centred on a sm
  segment reaches 12 px from centre, and the nearest neighbour edge is 59.3 + 4 = 63.3 px away, so
  it touches nothing. 44 px (AAA, 2.5.5) is not met at any preset in the vertical axis.
- Fitts, `ID = log2(1 + D/W)`:
  - adjacent step, `D` = 122.67 (segW + gap), `W` = 118.67: ID 1.02 bits (md, sm); lg (D 120,
    W 116): 1.02.
  - first to last, `D` = 245.33, `W` = 118.67: ID 1.62 bits.
  - vertical approach from above (assumption: entry distance `D` = 40 px, not measured; `W` = item
    height): sm 16 px gives 1.81 bits, md 24 px gives 1.42, lg 28 px gives 1.28. Landing tolerance,
    assumed as half the height: plus or minus 8, 12, 14 px.
- Neighbouring interference: a 4 px dead gap between cells (two for three options). A press
  there does nothing and shows nothing.
- Popup corridor: not applicable.

### Findings

Defects (source-reviewed, file and line cited):

1. **Tab trap in the tab-navigation group** (major, criterion 2.1.2, criterion owned by a11y-audit,
   shared: false). `Segmented.qml` 124-130: `step()` returns false at an end without wrapping, but
   the handler still sets `event.accepted = true` and refocuses. Person sees: Tab on the last
   option does nothing, and focus never leaves the group. The workbench unit `panel-tabs` has no
   exit; a host leaves only through its own keys, which this library does not provide. Fix: when `step()` returns false at an end, leave the event
   unaccepted so focus moves on, or name one exit key in the contract. The owner decides which,
   since the contract asks for focus to stay in the group.
2. **A selected, unavailable option loses its label in its own pill** (major, shared: false; fixed,
   source-reviewed, load-checked: the pill reads the selected option's own availability and dims
   with `Style.disabled`; pill (55, 45, 64) and dimmed accent label (101, 83, 113) are 1.88:1,
   computed, the same dim as any unavailable label, and the pill reads 1.20:1 against the track).
   `Segmented.qml` 173-174: the thumb reads `root.enabled` only, so the pill keeps the accent
   at full strength. Lines 220-222: the label is `Style.disabled(accent)` = (101, 82, 113) on the
   thumb (84, 72, 95), 1.21:1. Person sees: the current choice reads as an empty, full-strength
   pill with a faint word inside it. Fix: the thumb reads the selected option's own availability,
   and the disabled pill and label are chosen as a pair with a stated ratio.
3. **The clicked option moves the thumb before the host answers** (major, source-conflict with
   the record's own line 6, shared: false; fixed, source-reviewed, load-checked: `select()` no
   longer writes `currentIndex`; the unit's `host: refuses` control reaches it). `Segmented.qml` 92-98: `select()` calls
   `setCurrentIndex(index)` before `selected(index)`. The comment at 83-91 says a host binding is
   kept but not re-run, so a binding whose inputs did not change stays stale. A host that
   binds `currentIndex` to `profiles.indexOf(root.profile)` and calls `setProfile` on `selected`
   hits it: if the profile does not change, the binding never runs again,
   and the thumb stays on the clicked profile while the old one remains active. Fix: remove the
   local write; the host's answer moves the thumb. The cost is that `step()` then reads a stale
   index when a host answers late; state that trade-off with the owner.
4. **No visible focus when nothing is selected** (medium, shared: false; fixed, source-reviewed,
   load-checked: the ring goes to the first available segment while nothing is picked). `Segmented.qml` 313: the
   ring is drawn only on the selected segment; line 165 hides the thumb at `currentIndex < 0`.
   A host's binding can return -1 when its model reports a value outside the options. Person sees: Tab into the bar, and nothing marks where focus is. Fix: when nothing is
   selected, ring the first enabled segment, as `Segmented.md` line 37 already promises.
5. **The badge fills a sm segment and does not scale** (minor, shared: false; fixed in the chip
   height only, source-reviewed, load-checked: the chip is `rhythm(badgeHeight * s)`, 12, 16, 20 px
   at sm, md, lg, leaving 2, 4, 4 px of air; the 10 px text is `Badge`'s and still fixed; the unit's
   `badge: count` control reaches it). `Segmented.qml` 227
   gives a sm item 24 px; `Badge.qml` 53 fixes the badge at 16 px, so its tinted pill touches the
   thumb's top and bottom edges. At lg the badge stays 16 px with 10 px text while the label grows
   to 14 px. This breaks the component law that connected parts scale with the instance. Fix: pass
   a size into `Badge`, and give sm a dot or a clear inset.
6. **The selected thumb is 1.30:1 against the track** (medium, source-conflict, shared: true). The
   thumb at 12 percent accent is the only strong cue of the chosen option, because the label colour
   differs from its neighbours by 1.03:1. Non-text 1.4.11 asks 3:1 for a state indicator. The owner
   accepted the look ("No new motion or colour"), so this is the owner's ruling. Fix options are
   `opacity.selected` in tokens or a non-colour cue such as an edge.

Redesign proposals (taste, not defects):

- Keyboard-driven steps glide the thumb. review-animations standard 2 says keyboard-initiated
  actions get no animation. Skip the `Behavior` when the change came from `handleKey`.
- The thumb glide uses OutCubic. review-animations standard 3 asks for ease-in-out on screen
  movement. The change belongs to `Motion.standardEasing` (`Motion.qml` 120, shared).
- `Style.disabled` blends toward `band` (the frame), while a disabled label on the track sits on
  `surface`. Blending toward the layer it sits on is a shared change in `Style`.
- The unit: add empty, long, icon-only and badge fixtures; delete `middle-option`, which duplicates
  `unavailable: middle`.
- State the wheel contract in this record: no route, on purpose.
- The bar has no default accessible name. Require one at the consumer, or document the requirement.
- The value-choice use (battery) announces as `PageTab` with no panel. Whether a radio group fits
  value choices is an a11y-audit question under 4.1.2.
- The single gliding indicator is already listed in `docs/BACKLOG.md`; no new item here.

Source conflicts:

- Line 6 says the host owns `currentIndex`; `select()` writes it (defect 3).
- Lines 9-10 say the type serves panel tabs and value choices; the roles are tab roles
  (criterion 4.1.2, a11y-audit).
- Owner-accepted look against the 1.4.11 cue (defect 6).

Hypotheses (not measured, not in the table):

- H1: the thumb's `MultiEffect` shadow (lines 163-183) may be clipped by its layer bounds. Check live.
- H2: the focus ring's outer edge (4 px out) meets the neighbour's edge at a 4 px gap, so the ring
  may touch the next segment. Check live.
- H3: hover scale and colour run under reduced motion at 60 ms (`Motion.micro` under reduced
  motion), because `StateLayer` does not check `reducedMotion` (`StateLayer.qml` 126-131, shared).
- H4: a hovered 1.04 scale on a 12 px label may render soft.
- H5: Space and Enter on the focused bar do nothing; they work only after a mouse focuses a segment.
- H6: a mouse focus may hide the ring (Qt focus reason) as the component assumes. Not verified.
- H7: 10 px labels at sm may be hard to read at a distance.

Not examined: runtime and capture; live geometry; the workbench unit; a host's render; light and
high-contrast themes (only deep-night tokens read); RTL; scale factor; reduced motion at runtime;
screen reader and touch. Sibling: no `Segmented` in caelestia `components/controls/`. The nearest
is `modules/dashboard/Tabs.qml` (text tabs with a 3 px underline). It is a different pattern, so
it is compared for the `TabBar` wiring only.
