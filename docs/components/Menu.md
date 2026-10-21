# Menu

A keyboard-navigable container for rows; the host owns the model, the delegate and what activation does.
states: one `currentIndex` cursor over visible/selectable rows; navigation wraps, skipping headers, separators, disabled and report-only entries.
actions: `step(delta)` moves the cursor; `activateCurrent()` calls the selected row's `activate()` and reports `activated(index)` through the same route as a pointer. `rowAt(index)` and `rowCount` let hosts resolve identity and scroll the actual item into view. Static content and model with delegate feed the same rows.
boundary: `rowAt` exposes an Item for positioning/native input; activation keeps the consumer row's full protocol from the registry, without pretending every delegate is only a generic Item.
pointer: rows keep their own targets; the container claims no clicks and wheel passes through.
keyboard: arrows step along the orientation and Return and Enter activate the current row; the container is a focus scope and hands focus to the current row, so the row's ring shows. A row whose child already holds focus (an editor) keeps it.
screen reader: rows name themselves; the container adds no role beyond grouping.
size: rows stretch across the container on the cross axis. A vertical menu's natural width is the constant `Style.controlWidth` and long labels elide in their rows; a horizontal one is the sum of its rows' widths plus spacing. The main axis is unconstrained, so expanded entries never wrap into a second column. The menu does not clip, so a row's focus ring is not cropped; a ScrollArea in the owning composition bounds overflow and leaves the ring room.
tokens: space1 only; rows bring their own type, icon and space scales.
motion: none of its own; rows settle their own state changes.
not designed: the row itself, popover placement or dismissal; use ListRow, Popover or the host for those.

expected: shell Workbench → Compositions → menu-items contains Wi-Fi secure/open networks, BLE devices, ON/OFF switches, volume/mute, plain/secondary actions and unavailable/report-only/structural rows. Up/down selects items even from editors; left/right/N/O adjusts volume; password typing remains text. Enter/Escape returns from volume to its own item. Pointer and row activation answer the same operation once. Local fixtures show connection progress, retry and outcomes without hardware or password persistence; reset cancels them. The provider's menu-items JSON hosts one native MenuInteractions fixture; it is not a component story or another production component type.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | transient shell actions, reviewed together in one composition | owner wants control interactions, not another selector in a row | Menu + existing controls | owner completes value/toggle/connect routes |
| ia/interaction | audio, Wi-Fi, Bluetooth groups; one cursor, one row route; up/down always navigates | owner's keyboard contract; Caelestia MenuItem separates intent; APG menu uses arrow stepping | Menu.step/activateCurrent, Slider/TextField key hook | actual repeated keys and pointer operations |
| hierarchy/token | compact editor beneath the text column, no duplicate Volume label or extra box | owner rejected detached slider; blueprint rhythm and hierarchy | ListRow.contentInset, Style.spaceTight/space2; existing type scale | owner judges association and reveal |
| responsive/state | one scrollable column; availability follows radios; pending/failure/retry; drafts retained until reset | hidden input must not activate; no lost work or fabricated production success | ScrollArea, Field, cancellable local fixture | keyboard into view, radio off, submit/retry/reset |
| polish | restrained common surface, motion only for disclosure/state | Quiet Luminous and reduced-motion law | Style.overlay/radiusLg, Motion.fast | owner review, no automatic audit |

Not designed: real network/audio services, production action-menu identity repair,
arbitrary nested menus, screen-reader speech verification or a JSON menu framework.
No new design tokens. APG's action-only menu is not an ARIA role claim for this
mixed-control native composition; each actual control keeps its own accessible name.

## UIX audit

Evidence: source-reviewed only. No capture, no live geometry dump, no Workbench session, no keyboard or pointer run. Runtime-exercised: none. Owner-accepted: none. Read: `Menu.qml`, `ListRow.qml`, `StateLayer.qml`, `Surface.qml`, `Style.qml`, `Motion.qml`, `tokens/deep-night.json` (the only token file read), `workbench/units/Menu.qml`, `workbench/compositions/MenuInteractions.qml`, and caelestia `components/controls/Menu.qml`. Contrast figures are computed by hand from token values, not sampled from pixels; confirm them with `qsm-uix contrast` on a capture before any acceptance.

### Purpose and consequence

Lets a person pick one entry from a short list and sends that entry to the host's action. A wrong pick runs the wrong action (a danger row, Quit, sits in the same list as Cut). The component owns stepping and the thumb; the host owns the rows, the selection and what activation does.

### Controls, states, implemented

| Surface | Contract | Implemented | Note |
| --- | --- | --- | --- |
| `currentIndex` | host-owned (`Menu.qml:24-25`) | yes, but the component writes it | M-1 |
| `model`, `delegate`, `content` | consumer | yes | |
| `orientation` | vertical and horizontal | yes; horizontal `implicitWidth` is the sum of row widths plus spacing | a horizontal menu's rows contribute their label width until `ListRow` offers a constant; no consumer uses horizontal |
| `spacing` (`space1`), `radius` (`childRadius`) | consumer | yes | |
| `activated(index)`, `step`, `activateCurrent`, `rowAt`, `rowCount`, `resync` | listed | yes | |
| `actions`: step-previous, step-next, activate-current | listed | yes | enabled follows `root.enabled` and selectability (`Menu.qml:42-44`) |
| `enabled: false` | disabled state | keys and activation refuse; no visual state | M-4 |
| `currentIndex: -1` | no cursor | thumb hidden (`Menu.qml:77`); no row holds focus | |
| zero rows | empty | 0 by 0, nothing drawn (`Menu.qml:37-39`); the consumer supplies the text | P5 |
| failure, cancel | none | none; Escape is not handled here (dismissal is the host's, per AGENTS) | |

Sizes: the Menu has no `size`. Rows take the ListRow size table (`Style.size("ListRow", size)`): sm 32, md 40, lg 56 px.

### Routes (real ones)

- **Pointer.** A row's `StateLayer` tap calls `ListRow.activate()` (`StateLayer.qml:170`, `ListRow.qml:195`), which emits `activated`; the Menu handler sets `currentIndex` then emits `activated(index)` (`Menu.qml:150-151`). Hover lifts the row body (`ListRow.qml:159-171`), and the thumb's hover lift applies only when the hovered row is current (`Menu.qml:74`). Hover does not move the cursor; `ListRow.hoveredEntered` (`ListRow.qml:126`) exists and the Menu does not use it (P3).
- **Keyboard.** Up and Down step a vertical menu (`Menu.qml:211-212`); Left and Right a horizontal one (`213-214`); Return and Enter activate with auto-repeat filtered (`215-216`). Return calls `activateCurrent()` (`204-209`), which calls the same `row.activate()` as the pointer, so one gesture yields one activation. The pointer also moves the cursor and the keyboard does not, which is M-1. Home, End, typeahead: absent (P1, P2).
- **Wheel.** The Menu has no wheel handler; wheel events reach the `ScrollArea` that owns overflow.
- **Focus.** The Menu is a `FocusScope` with `focus: true` and no `activeFocusOnTab`. On focus-in and on every cursor change it moves focus to the current selectable row (`_focusCurrent`), so `ListRow.focused` (its own `activeFocus`) lights the ring; with no selectable current row no row keeps focus. Hosts inside a clipping ScrollArea leave `2 * Style.spaceTight` of room for the ring. See C1.
- **Accessibility.** The Menu has no `Accessible` block. Rows report `Button` and a name (`ListRow.qml:128-129`), not the current state. Handed to a11y-audit (below), not ruled here.

### Pointer geometry

- Input shape: one `StateLayer` per selectable row (`ListRow.qml:181-197`), full Menu width by row height (`_headingHeight`, `ListRow.qml:104-105`). Painted body and thumb are the same size, so input equals paint with no overhang. Trailing controls sit above the layer and take their own clicks (`ListRow.qml:179-180`). Headers, separators and report-only rows have no layer and no target.
- Dead band: `Menu.qml:28` sets the gap to `space1` 4 px. The gap belongs to no target: 4 of each 48 px pitch, 8.3 %.
- Width model: W is the hit height along vertical travel (the row height); D is the centre-to-centre pitch (height plus gap); ID = log2(1 + D/W), the Shannon form. Lateral entry has W equal to the full row width; not measured.

| size | W (hit height) | D (pitch) | ID (bits) |
| --- | --- | --- | --- |
| md | 44 | 48 | 1.06 |
| sm | 36 | 40 | 1.08 |
| lg | 56 | 60 | 1.05 |

- Landing tolerance: about ±W/2 around each row centre (±22 px at md) before a click lands on a neighbour. The 4 px gap is dead for ±2 px around each boundary.
- Neighbouring interference: no hit areas overlap; the dead band is the only interference (H1).
- Trigger-to-panel corridor: not applicable. The Menu is not a popup; the host's popover or rollout owns that corridor.
- Label origins (assumed, not measured): with an icon, text starts at `space3` 12 + `iconLg` 24 + `space2` 8 = 44 px at md (`ListRow.qml:109-111`, `leadingBox` 24 px); without an icon, 12 px (`ListRow.qml:259` hides the box). Label weight: not in the tokens; assumed regular at `typeSm` 12 px (`Style.qml:194`).

### Visual roles and palette pairs

Roles: `band` is the Menu background (`Menu.qml:54-58`); `surface` is the thumb (`Menu.qml:60-86`); `accent` is the selected name (`ListRow.qml:81`); `textMuted` the header and supporting line (`ListRow.qml:216, 301`); `danger` the danger name (`ListRow.qml:118`). The Menu reads only `Style` and `space1`.

| pair | fg on bg | ratio (computed) | verdict |
| --- | --- | --- | --- |
| label, not receded, on band | `#f0ecf5` on `#271e30` | 13.71 | pass |
| header and supporting, on band | `#c5bad1` on `#271e30` | 8.61 | pass |
| selected name on thumb | `#d9b4ea` on `#4e4159` (accent 12 % over surface) | 5.25 | pass, 4.5 |
| selected danger name on thumb | `#f5aeb7` on `#514053` | 5.26 | pass, 4.5 |
| receded label (text recede 0.70 over band) | `#f0ecf5` at 0.70 on `#271e30` | 7.38 | pass |
| receded supporting (muted recede 0.70) | `#c5bad1` at 0.70 on `#271e30` | 4.95 | pass |
| receded danger name | `#f5aeb7` at 0.70 on `#271e30` | 5.06 | pass |

The focus colour is `accent`; its ratio against the adjacent band is not measured here.

### Motion and reduced motion

- Thumb x, y, width and height slide at `Motion.micro` (130 ms, `tokens` motion.micro; 60 ms under reduced motion, `Motion.qml:26`) with `standardEasing` (`Menu.qml:81-84`). Under reduced motion or while hidden, the position and size jump (`enabled` false). The thumb's opacity fades at `micro` (`Menu.qml:85`).
- Rows: prose colour `ColorAnimation` at `micro` (`ListRow.qml:288`); recede colour at `micro`; expansion height at `Motion.fast` (`ListRow.qml:328`), off under reduced motion.
- The verdict on these durations and curves belongs to review-animations.

### Findings: source-backed defects

| id | file:line | summary | evidence | fix | shared | severity |
| --- | --- | --- | --- | --- | --- | --- |
| M-1 | `Menu.qml:199`, `:150` | The Menu writes the host-owned `currentIndex` on a keyboard step and on a row click, which replaces any host binding. This is the qss-bcn issue, confirmed. | `Menu.qml:24-25` declares the selection consumer-owned. `workbench/units/Menu.qml:30` binds `currentIndex: root.currentIndex`, and the unit's selection controls (`units/Menu.qml:84-88`) write through it. After the first step or click the binding is gone, so later control changes stop moving the thumb. | `step()` and the row handler emit `moved(int index)` and never assign `currentIndex`. Keep `activated(index)`. Hosts bind `currentIndex` and answer `moved`. Consumers that bind nothing lose keyboard stepping, so each host must wire it: the unit and `MenuInteractions.qml`. | true | major |
| M-2 | `Menu.qml:163`, `:152` | The Menu writes each row's consumer-owned `selected` (`ListRow.qml:46`) and `paintsSelection` (`ListRow.qml:85`). | `_applySelection` runs on every resync and every cursor change (`Menu.qml:157, 224`). No in-repo binding to a row's `selected` was found in the files read, so the harm is latent. | The Menu drives a Menu-owned `current` property on `ListRow` for the prose tint and the thumb, leaving `selected` to the consumer. `paintsSelection` is set once by the Menu, not per change. | false | minor |
| M-4 | `Menu.qml:182`, `:192`; `ListRow.qml:94`, `:117-120` | A disabled Menu shows no disabled state. Only the keyboard path checks `root.enabled`. | Rows read `disabled` and `interactive`, never the Menu's `enabled`, so the rows keep full strength. Pointer input is probably cut by Qt's inherited `enabled`; this assumes that and needs a runtime check. | `ListRow.proseColor` reads the inherited `enabled` and uses `Style.disabled` when false. No write from the Menu is needed. | false | major |

While the Menu writes `currentIndex` itself (M-1), `_resync` (which keeps the cursor on the same row object, then on its `objectName`, then clamps) can replace a host binding. M-2 needs a Menu-owned `current` on `ListRow`; until then the Menu writes `selected`, and the `paintsSelection` write happens only when the row still paints its own. M-4 is a `ListRow.proseColor` and glyph colour change.

### Proposals (taste and design, not defects)

- P1. Home and End jump to the first and last selectable row (APG menu pattern).
- P2. Typeahead by first letter. Optional, not needed for the MVP.
- P3. Hover reports intent: move the cursor on `ListRow.hoveredEntered` (`ListRow.qml:126`). Today the row's own lift and the thumb mark one pointer position twice.
- P4. Dead band: 4 px between rows belongs to no target. Either grow each layer by half the gap, or set `spacing` to 0 and draw rules. Measure live first (H1).
- P5. A zero-row Menu draws nothing (`Menu.qml:37-39`). Keep it that way, or accept an empty slot so the consumer's empty text is part of the component.
- P6. Caelestia (`components/controls/Menu.qml`, `MenuItem.qml`): an anchored popup with outside-click dismissal, a 0.1 to 1 open scale, a per-item active tint and rounded group ends. It has no keyboard stepping and writes its own `active` on click, so it is no precedent that settles M-1. The rounded group ends are a pattern to weigh for `band` (taste).

### Source conflicts (owner ruling)

- C1. Focus owner. `Menu.md` line 8 says "the container holds focus for its rows", but the Menu is a `FocusScope` that moves focus to the current row, so the row holds it. The owner rules which is intended.
- C2. Leading box. `ListRow.qml:17-19` says the leading box has one size so the name never moves. `ListRow.qml:259` hides the box without an icon, so the text starts at 44 px with an icon and 12 px without (`ListRow.qml:109-111`). Mixed lists shift their names.

### Hypotheses (observed in source, not measured)

- H1. The 4 px dead band drops clicks: a click 2 px inside a boundary lands on nothing. Check live.
- H2. A mixed-icon list shifts its names (C2). Check whether a host's items mix icons.
- H3. The hover double cue (P3) is visible on a live pointer.
- H4. Long labels wrap or elide: `Prose.qml` not read.
- H5. Hover lift and press colour of the thumb are unmeasured.

### Handed to a11y-audit (not ruled here)

- Tab entry: no `activeFocusOnTab` on the Menu (`Menu.qml:47`) or on rows. A keyboard user has no Tab stop into a Menu unless the host focuses it.
- Name, role and state: no `Accessible` block on the Menu; rows report `Button` and a name but not the current state (`ListRow.qml:128-134`).
- Focus indicator, keyboard route, reduced motion and 200 % text: not run.

### Not examined

No captures, no live geometry, no Workbench session, no keyboard or pointer run, no screen reader. Only `tokens/deep-night.json` was read, so no other theme is examined. Not read: `Prose.qml` (label elision), the rest of `StateLayer.qml` ring geometry (only lines 150-157), and the `Item.enabled` inheritance (assumed). Horizontal orientation, `sm` and `lg` visuals, monitor parity and reserved space were not examined. Motion verdict: review-animations.
