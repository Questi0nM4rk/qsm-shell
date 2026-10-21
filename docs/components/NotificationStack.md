# NotificationStack

The ephemeral notification window lets the person read a new result and, when its current source offers a default action, open that source without interrupting the application underneath. The host owns which notifications exist, their expiry and protocol consequences; the stack owns only rendered presentation and forwards card intent.

states: input is newest-first, rendered oldest-first from top to bottom; active cards, overflow-evicting snapshots, retained last body and fully empty. Retiring rows are paint, not input targets; replacement refreshes default availability in place.
actions: cards report dismiss, hover and `primaryTriggered(entry)` upward; the stack forwards `primaryActionRequested(entry)` only for an active eligible row. It never resolves an action ID or applies a consequence.
pointer: cards keep one `StateLayer` body-tap route, swipe and middle-click arbitration; expanded vertical body scrolling does not also trigger vertical expansion, horizontal dismissal remains available, and the stack claims no events or unconsumed wheel input.
keyboard: cards expose a primary tab stop only while host availability and row input eligibility are both true, and only a focus-capable host can deliver it. A host that gives the popup window no keyboard focus leaves it without a native keyboard route, and arrival does not steal focus. Native popup key reachability is unverified and not claimed.
screen reader: available primary cards expose a named button; unavailable cards remain readable text. Stack adds no role beyond ordering.
size: width follows the column and height follows actual empty/preview/expanded row sizes minus the evicting share; `rowSpacing` (default zero) is the column's gap and is added once per departing row to the eviction shift, so survivors land where the shift stops. The stack forwards `bodied` and `bodyRadius` to every card (and drops the divider when bodied) without acquiring a styling policy. A new row's gap appears with its first frame; the host's body does not animate its size.
tokens: notificationWidth, notificationPreviewHeight, notificationBodyViewportHeight and the reveal Motion set; cards bring their own roles.
motion: one reveal-curve eviction shift; row entrance and expansion supply their animated heights to the layout and silhouette directly. Eviction does not also run a Column move transition; its removal handoff lays out the survivors before clearing the shift. A frozen row is excluded from the "a row height is still moving" test, because its stopped entrance is a deliberate hold rather than a live height pulse. A departure still sliding when the window empties is held at its current offset, so the retained last body keeps the extent the owner last saw instead of shrinking through the rollout's retract; an arrival releases that hold and resumes any departure still owed. Reduced motion shortens the durations.
not designed: history, search, grouping or card content; use NotificationCenter, NotificationCard or the host for those.

## Lifetime correction

`NotificationStack.qml` reconciles owned payload snapshots into incremental rows
keyed by `notificationId`; same-ID publication updates a row without replacing
its card. Nested action values are copied. The host continues to publish a
newest-first window and answer `isAlive(id)` against its current source model.
`retainWhenEmpty` defaults to false; a host binds it to the visible lifetime of
its presentation (Rollout or DataCapsule) when the final rendered composition
must ride the fade/retract.
`inputEnabled` defaults to true and follows the host's open intent, withdrawing
input at retract start while preserving the current presentation.

| layer | decision | why / source | token or pattern | owner-review evidence, when prepared |
| --- | --- | --- | --- | --- |
| posture | Transient feedback; no focus steal or task modal | Existing popup purpose | Non-modal notification window | Arrival leaves the current application usable |
| task | Read one notification and optionally activate its current default, then dismiss it | Same-ID updates are new content, not new notifications | Stable notification identity | Replacement updates content/action availability in place, without a new entrance |
| ia | Keep the host's newest-first window; render oldest above newest | Existing stream choreography | Keyed rows by `notificationId` | Arrival at the cap moves the oldest out above |
| interaction | Separate source lifetime, display record and row eligibility; forward primary intent only from an eligible live row | Service destroys sources; Card reports intent without protocol policy | Owned value snapshot + current-ID intent routing | Retired row cannot emit; replacement uses its latest availability; production current-default callback resolves through the lexical stack ID |
| hierarchy | Preserve urgency, expansion and readable message content; forward row material (`bodied`, `bodyRadius`) and gap without deciding them | Card anatomy plus caller-owned presentation | `NotificationCard`, `showActions: false`, `bodied`, gap | Replacement keeps the same expanded card; gaps do not create extra removal motion |
| token | Use fixed preview natural size, a bounded expanded body viewport, and existing movement tiers | Headline-only 36px composition cannot hold the requested preview | `Style.notificationWidth`, `Style.notificationPreviewHeight`, `Style.notificationBodyViewportHeight`, `Motion.revealSmall` | Short/long messages do not change collapsed size; stack growth remains bounded |
| responsive | Keep local row bounds distinct from mapped scene/input bounds | `cardGeometry()` → host wrapper → ShellBorder | Local clipped geometry + host mapping | A clipped/retiring row opens no fullscreen input hole |
| state | Last removal freezes content and actual body dimensions until host retreat ends | Shared terminal-handoff law in `docs/12-mechanism.md` | Explicit host retention, neutral hidden endpoint | Expanded last card retracts intact; fully hidden releases its record |
| polish | Same-ID updates preserve delegate state; removal cannot replay entrance | Snapshot changes must not recreate the presentation | Keyed model reconciliation | No repeat micro-pop, expansion reset or post-close recovery |

### Ownership and boundary

- **Ingress:** unique stable `notificationId` (number or nonempty string), required
  string `appName` and `summary`; optional Card fields retain their meaning. Copy
  nested action values too; preserve `swatch`, `paused`, image and timestamp data.
  No QObject, protocol source, callbacks or service methods enter render records.
- **Library:** reconcile owned rows by ID using incremental `ListModel` inserts,
  updates, moves and removals, not a replacement JS array as the delegate model.
  Same ID updates payload without
  becoming a fresh arrival, replaying entrance or losing pointer/drag/expansion
  state; ordering still follows the host's current window.
  Evicting rows keep their departure snapshot. A returning ID reclaims its row;
  a stale animation completion must not delete that newly active row.
- **Host publication:** expose a reactive, plain presentation record from each
  entry and a popup-record projection from the host's service.
  Publish coherent content after each update, and pause changes,
  even when the live entry array stays unchanged. Keep `live` objects for service
  ownership and current-ID operations;
  this projection is derived data, not a second notification store.
- **Retention and input:** `retainWhenEmpty` (default false) follows the
  presentation's visible lifetime. `inputEnabled` (default true) follows its open
  intent, so input withdraws when retract starts, not when paint disappears.
  Freeze expansion before disabling the active cards. When the host is hidden,
  release the retained composition.
  An arrival during retreat reconciles with the current presentation, cancels
  obsolete cleanup and lets the existing Rollout retarget. No new expiry owner.
- **Input:** active rows alone can report dismiss/hover intent. Withdraw input as
  soon as the row leaves the offered popup window or the host begins dismissal,
  not after paint disappears. Pair any previously reported hover with release so
  an overflow-evicted live entry cannot stay paused indefinitely. Do not dim the
  retained composition or collapse it as a side effect of disabling handlers.
- **Geometry:** `cardGeometry()` reports row phase and actual interactive
  eligibility; its local rect is clipped to the stack viewport. The wrapper maps
  eligible rows into scene coordinates for fullscreen input registration instead
  of equating service liveness with interactivity. `geometryChanged` must also
  report eligibility changes with unchanged dimensions. The host still owns
  mapping, border registration and compositor masks; the stack sees no screen.

Rendered path: service record → keyed row/Card → stack clip → Rollout full body
and exposed viewport → ShellBorder registry/shader → host input region →
host-hidden release. Card and stack coordinates are local; the Rollout maps its
selected paint contour into the host for registration. The attached notification
wrapper uses expansion without changing the stack's own row motion or lifetime.
Fullscreen keeps its separate presentation. The intended composition contains
one animated row extent in one padded `DataCapsule` body, like OSD. Fullscreen per-row
registrations describe eligible input only, never a second set of painted card
backgrounds. The same stack instance and service lifetime cross the host change;
last-row retention follows the selected host's visible/fading lifetime.
The previously reviewed capsule composition predates the resting body preview
and default-action affordance. Its visual acceptance does not cover this revised
composition; owner review remains pending.
One animated row extent drives the column, stack viewport and body: the host wrapper disables the
Rollout's additional size morph. Expanded text cannot precede its painted body.
Overflow removes the departing row's actual height progressively with the shift,
not a collapsed-height estimate removed at arrival. Survivors are laid out before
the completed shift is cleared. The shader formulas and origin-wall endpoint
remain unchanged. Runtime evidence does not establish visual acceptance.

### One review example

Use the existing `workbench/units/NotificationStack.qml`: a file transfer moves
from "Transfer started" to "Transfer complete" under the same ID, with a
current-default and no-default variant. Offer arrival at the cap, replacement,
middle removal, last removal and arrival during retreat. Its fake host answers
primary intent with fixture callback evidence only, and binds retention to a
genuine Rollout; no lifetime workaround in the unit. Pointer hover, swipe and
middle-click stay native. Expose records, row identity/phase and eligible
geometry through the existing backend contract, not a new harness API.

The unit uses a genuine `Rollout`, `ShellBorder` and `ScenePointer`; its
scenario controls mutate the host model and answer dismiss/hover intent. Native
targets expose the actual cards for replacement, hover, swipe and dismissal.
Expiry remains a host removal here; timer policy is the host's.
Focused
QML integration coverage lives in `tests/units/tst_NotificationStack.qml`.

References: Caelestia `services/NotifData.qml` (`lock`/`unlock`/`close`) and
`modules/notifications/Content.qml` (`NotifWrapper`, delayed removal and input
withdrawal); [Radix Toast](https://www.radix-ui.com/primitives/docs/components/toast)
(controlled open state separate from `forceMount`). Reuse the lifetime separation,
not Caelestia's service locks, swipe-out choreography or Radix's timer policy.
These are reference patterns, not a claim that our notification policy is universal.

Source conflicts: live-reference rendering violated this stack's existing
snapshot promise; popup input used service liveness instead of rendered
eligibility; the expanded-dismiss flow treated a settled card as proof that its
Rollout body and registered silhouette were settled too. The component addresses
the first two; a host flow observes the full geometry handoff. No new
visual direction, type scale, responsive layout or tokens are proposed; those
design steps retain the current component decisions. Owner review remains pending.
expected: same-ID replacement keeps one card current; destroyed sources leave no
render references; last content and dimensions survive retreat, then release;
retiring rows accept no input or hover retention; removing a hidden presentation
changes no visible border. Runtime checks and owner review establish outcomes,
not source review alone.

## UIX audit

Evidence here is source-reviewed only. Channels used: the source files named below. Not used: captures, live geometry, pointer or key driving, and any Workbench session, which the audit brief forbids. Themes: `tokens/deep-night.json` is the only theme file, so light and high-contrast parity is not examined. The card-level defects sit in `NotificationCard.qml` because the stack renders only rows; they are listed here because they decide what this component shows.

### Purpose and consequence

The stack finishes one task: the person reads a new result in the passing popup, optionally opens its default source, then dismisses it. When it fails, a new result is missed, or a critical one reads as a routine one (D4).

### Controls and states

Expected library contract: inputs `stack`, `isAlive`, `swatchFor`, `retainWhenEmpty`, `inputEnabled`, `bodied`, `bodyRadius`, `rowSpacing`; signals `dismissRequested`, `hoverChanged`, `primaryActionRequested`, `geometryChanged`; function `targetForNotification`. All implemented (`NotificationStack.qml:13-32`, `:91-94`).

Stack states: active, evicting (overflow departure), retained (last body while the host is visible), empty (height 0, `:377`), input withdrawn (`:324-335`). All implemented. Evicting and retained rows take no input (`:164`, `:225`).

Card states (`NotificationCard.qml`): rest, hover-expanded (only with a body, `:90-91`, `:258-261`), primary available (default action, `:94-96`, `:199-202`), unread dot (`:394-401`), selected (bodied only, `:329`), archived (`:92`), swipe drag (`:642-672`), vertical drag expansion (`:664-666`), paused (`:91`). All implemented in source.

Not implemented: keyboard dismissal (D2), a rendered focus indicator (D1). The popup has no action row by design (`showActions: false`, `NotificationStack.qml:427`).

### Routes

| route | real path | source |
| --- | --- | --- |
| pointer hover | StateLayer over the whole card | `NotificationCard.qml:580-585` |
| pointer click on body | runs the default action when available, else `activated` | `:586-596` |
| middle click | dismisses | `:626-630` |
| horizontal swipe | dismisses past 40 percent of card width | `:642-672` |
| vertical drag | sets `dragExpanded` past 20 px | `:664-666` |
| wheel | consumed only over an expanded, scrollable body; otherwise passed on | `:507-521` |
| keyboard | Tab stop only when primary is available (`:614`); Return, Enter, Space activate (`:616-624`); no dismiss key; no navigation between rows | `:614-624` |
| focus indicator | none rendered (D1) | `StateLayer.qml:72`, `NotificationCard.qml:580-597` |
| reset and cancel | `clearPresentation` releases hover and clears rows (`NotificationStack.qml:308-320`); removal releases hover (`NotificationCard.qml:441-446`, `:473-476`) | |
| accessible role | primary card is a Button named `label: summary` (`:112-117`); others are StaticText named `app: summary`; description is the raw body (`:116`, D10) | |

The stack adds no role beyond ordering, oldest first from top to bottom.

### Sizes, empty and long content

| case | rest height | hover-expanded height | source |
| --- | --- | --- | --- |
| no body | 36 | 36 (nothing to open) | `NotificationCard.qml:253-261` |
| one line of body | 68 | 68 | `:256-257` |
| two lines | 80 (capped; natural 88) | 88 | `:256-257`, `:427` |
| three lines | 80 | 108 | `:258-261`, `:470-472` |
| four lines | 80 | 128 | `:470-472` |
| five or more lines | 80 | 144, body scrolls in a 96 px viewport | `:470-472` |

Derived values: line height 20 px, because `Style.rhythm(12 x 1.55 = 18.6)` rounds to the 4 px grid (`Style.qml`, `rhythm`). Text is 12 px (`type.sm`). Card width is 380 (`geometry.notificationWidth`). The library's default row gap is 0; a host sets its own (`rowSpacing`). An empty stack is 0 px tall. Long summaries are not elided in the card; `Prose` elision is not examined.

### Visual roles and palette pairs (source values, not measured)

| element | role | token value | on |
| --- | --- | --- | --- |
| card body (bodied) | surface | `#3b3145` | band `#271e30` |
| title | text | `#f0ecf5` | surface |
| body, metadata, app name | textMuted | `#c5bad1` | surface |
| normal glyph | info | `#89cff1` | surface |
| critical glyph | danger | `#f5aeb7` | surface |
| low glyph | textMuted | `#c5bad1` | surface |
| pressed title, unread dot | accent | `#d9b4ea` | surface |
| focus ring (not rendered, D1) | focus | `#d9b4ea` | not applicable |

Contrast ratios are not computed here. They need the ui-audit pass on the rendered pixel (channel 4).

### Motion and reduced-motion form

| motion | duration, normal / reduced | curve | source |
| --- | --- | --- | --- |
| entrance: opacity, scale 0.97 to 1, height from 0 | Motion.microPop 120 / 60 | emphasized | `NotificationCard.qml:267-281`, `:271-273` |
| expansion height | Motion.fast 180 / 80 | emphasized | `:283-290` |
| body text cross-fade | Motion.fast 180 / 80 | emphasized | `:433-435`, `:463-465` |
| eviction slide of the column | Motion.revealSmall 250 / 120 | revealCurve | `NotificationStack.qml:344-352` |
| survivors' move | Motion.revealSmall 250 / 120 | revealCurve | `:399-408` |
| swipe spring-back | Motion.fast 180 / 80 | standardEasing | `NotificationCard.qml:637-639` |

Reduced motion shortens durations and keeps the scale and the slide (D7). `Motion.qml:38-40` says the micro-pop scale is kept on purpose, which conflicts with the AGENTS law on one-shot position animation.

Read against review-animations, from source: exit runs 250 ms against an entry of 120 ms, the reverse of "exit about 20 percent shorter" (D6), and the slide and scale keep moving under reduced motion (D7). This is a source reading; the verdict belongs to a run.

### Pointer geometry

- Input shape: the card's StateLayer fills the card, 380 by rest height. The painted body is the same rectangle (`Surface` fills the card), so input and paint agree. The shadow reaches 12 px outside and takes no input.
- Leading-column route: hidden in the popup (`leadLayer.visible: !expandOnHover`, `NotificationCard.qml:607`), so each row is one target.
- Dead zone: the gap between rows (8 px in the host) belongs to no card, so hover ends there.
- Width model: one-dimensional, along the vertical movement axis. W is the row's rest height. A horizontal approach to the card's edge uses W = 380.
- Distance D is not measured. The table below uses two modelled values, D = 100 px and D = 200 px. These are assumptions, not a human average.
- Index of difficulty, ID = log2(1 + D/W):

| W (rest height) | D = 100 | D = 200 |
| --- | --- | --- |
| 36 (no body) | 1.92 bits | 2.71 bits |
| 68 (one line) | 1.30 bits | 1.98 bits |
| 80 (two or more lines) | 1.17 bits | 1.81 bits |

- Landing tolerance: plus or minus W/2 vertically, that is 18, 34 and 40 px for the three rest heights, before the pointer leaves the card.
- Neighbour interference: expanding a row with a body grows it by delta within 180 ms and moves every row below by delta. Delta is 0, 8, 28, 48 and 64 px for one through five or more lines (D5). The Column move transition is off while heights animate (`NotificationStack.qml:399-401`), so rows below follow the growth frame by frame: a moving target.
- Corridor and timing: this component has no trigger. The Rollout hitbox and corridor belong to `Rollout.qml` and were not measured. Hover expansion starts without delay. A host pauses expiry on hover.

### Findings

Defects (source-backed, each with file, line and fix) are the list returned with this audit, D1 to D11:

- Focus and keyboard: D1 (no focus ring), D2 (no keyboard dismissal).
- Information: D4 (urgency lost for image and swatch entries).
- Motion and layout: D5 (moving target), D6 (exit slower than entry), D9 (two-line preview without bottom inset).
- Source conflicts, owner ruling needed: D7 (reduced motion), D8 (rest height depends on content, against this record's own table row and the natural-size law).
- Discoverability and accessibility text: D3 (no visible dismiss), D10 (description carries markup).
- Law breach: D11 (literal 60-second interval in a component).

Redesign proposals (taste, not defects):

- P1: Newest row beside the anchor edge. The popup anchors at the top, but the newest row lands last, at the far end (`NotificationStack.qml:240-241`). The record calls this existing stream choreography (ia row above); the owner should confirm it.
- P2: A group name and list semantics for the stack, so a screen reader announces the count before the rows. Today only the row order is spoken.
- P3: Invalid entries drop silently (`NotificationStack.qml:59-64` returns null and the row never appears). The host cannot learn that a notification was refused; a signal would let it report.

Hypotheses (unmeasured, need channel 1 or 2):

- H1: The card's 12 px shadow may be clipped at the layer bounds. `NotificationCard.qml:303-311` sets no layer padding, and the wider viewport (`NotificationStack.qml:379-391`) helps only if the layer paints beyond its item.
- H2: The top-flush clip cuts the side shadow at the stack's top edge, a hard horizontal line 12 px wide at each top corner (`NotificationStack.qml:379-383`).
- H3: The 12 px shadow reach is larger than an 8 px host inner padding, so up to 4 px of shadow may sit outside the painted body on the outer sides.
- H4: A pointer crossing the 8 px dead zone during a 180 ms collapse may land on a different row.
- H5: `evictHeight` (`NotificationStack.qml:112-120`) reads cards through `itemAt` inside a binding, so its updates depend on the cards it tracked last. A stale value is possible; not reproduced.
- H6: The unread dot (`NotificationCard.qml:394-401`) has a name but no role; it may expose an unnamed node or none. Not tested.

Accessibility conformance (a11y-audit method, source only; criteria from WCAG 2.2):

| criterion | verdict | evidence | surface |
| --- | --- | --- | --- |
| 1.3.1 info and relationships | not tested | row order only; no tree dump taken | stack |
| 1.4.1 use of colour | pass (source) | glyph shape differs by urgency (`NotificationCard.qml:205-207`); image and swatch entries show no cue at all (D4), which is absence, not colour alone | card |
| 1.4.3 contrast (minimum) | not tested | ratios not computed; ui-audit channel 4 | card |
| 1.4.4 resize text | not tested | no 200 percent run | stack |
| 1.4.11 non-text contrast | not tested | no rendered indicator to measure (D1) | card |
| 1.4.13 content on hover | pass (source) | expanded body stays while hovered (`NotificationCard.qml:580-585`) and leaves when the pointer leaves | card |
| 2.1.1 keyboard | fail (source) | dismissal and the expanded body have no key route (D2; `:616-624`, `:626-630`) | card |
| 2.1.2 no keyboard trap | pass (source) | no focus scope | stack |
| 2.2.1 timing adjustable | not tested | expiry is host policy; the host's hover pause was not read in full | host |
| 2.4.3 focus order | pass (source) | tab stops follow column order, top to bottom | stack |
| 2.4.7 focus visible | fail (source) | no ring rendered (D1) | card |
| 2.4.11 focus not obscured (AA, WCAG 2.2) | not tested | needs live geometry | host |
| 2.5.3 label in name | pass (source) | name `label: summary` contains the visible summary (`:112-115`) | card |
| 2.5.7 dragging movements | pass (source) | swipe has a click alternative (middle click) and expiry | card |
| 2.5.8 target size (minimum) | pass (source) | smallest row 380 by 36, above 24 | card |
| 4.1.2 name, role, value | pass (source), with caveat | roles and names set; expansion state not exposed; description carries markup (D10) | card |
| 4.1.3 status messages | not tested | no live region for arrivals; platform behaviour not checked | stack |

Evidence: source-reviewed for every row. Runtime-exercised: none. Owner-accepted: none.

Not examined:

- No captures, no live geometry, no pointer or key driving, no Workbench session (forbidden by the brief). Every number above comes from source and tokens.
- Themes: only `tokens/deep-night.json` exists; light and high-contrast parity not examined.
- Contrast ratios and the 200 percent text scale.
- Long summaries (`Prose` elision) and `SvgIcon` glyph rendering.
- Rollout corridor and hitbox geometry.
- Caelestia: `~/Clonned/caelestia/repo/components/controls/` holds no notification type, so there is no sibling for a visual comparison. Caelestia's notification code lives in `modules/notifications/`, a lifetime reference only, as the record already states.
