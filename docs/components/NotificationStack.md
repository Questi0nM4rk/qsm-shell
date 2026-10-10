# NotificationStack

The ephemeral notification window lets the person read a new result and, when its current source offers a default action, open that source without interrupting the application underneath. The host owns which notifications exist, their expiry and protocol consequences; the stack owns only rendered presentation and forwards card intent.
states: input is newest-first, rendered oldest-first from top to bottom; active cards, overflow-evicting snapshots, retained last body and fully empty. Retiring rows are paint, not input targets; replacement refreshes default availability in place.
actions: cards report dismiss, hover and `primaryTriggered(entry)` upward; the stack forwards `primaryActionRequested(entry)` only for an active eligible row. It never resolves an action ID or applies a consequence.
pointer: cards keep one `StateLayer` body-tap route, swipe and middle-click arbitration; expanded vertical body scrolling does not also trigger vertical expansion, horizontal dismissal remains available, and the stack claims no events or unconsumed wheel input.
keyboard: cards expose a primary tab stop only while host availability and row input eligibility are both true, and only a focus-capable host can deliver it. Production `EdgeScene` assigns `WlrKeyboardFocus.None` unless a listed modal is active, so the passive popup has no native keyboard route and arrival does not steal focus; the notification-center shortcut remains a separate route. Native popup key reachability is unverified and not claimed.
screen reader: available primary cards expose a named button; unavailable cards remain readable text. Stack adds no role beyond ordering.
size: width follows the column and height follows actual empty/preview/expanded row sizes minus the evicting share; rows have no gaps.
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
| posture | Transient feedback for the desktop owner; no focus steal or task modal | Existing popup purpose, desktop spec 04 | Non-modal notification window | Arrival leaves the current application usable |
| task | Read one notification and optionally activate its current default, then dismiss it | Same-ID updates are new content, not new notifications | Stable notification identity | Replacement updates content/action availability in place, without a new entrance |
| ia | Keep the host's newest-first window; render oldest above newest | Existing stream choreography | Keyed rows by `notificationId` | Arrival at the cap moves the oldest out above |
| interaction | Separate source lifetime, display record and row eligibility; forward primary intent only from an eligible live row | Service destroys sources; Card reports intent without protocol policy | Owned value snapshot + current-ID intent routing | Retired row cannot emit; replacement uses its latest availability; production current-default callback resolves through the lexical stack ID |
| hierarchy | Preserve the boxless urgency tick and hover expansion; show app, summary and body preview at rest | Existing Card anatomy plus production-actions requirement for useful message content | `NotificationCard`, `showActions: false` | Replacement keeps the same expanded card; preview is visible without hover |
| token | Use fixed preview natural size, a bounded expanded body viewport, and existing movement tiers | Headline-only 36px composition cannot hold the requested preview | `Style.notificationWidth`, `Style.notificationPreviewHeight`, `Style.notificationBodyViewportHeight`, `Motion.revealSmall` | Short/long messages do not change collapsed size; stack growth remains bounded |
| responsive | Keep local row bounds distinct from mapped scene/input bounds | `cardGeometry()` → desktop wrapper → ShellBorder | Local clipped geometry + host mapping | A clipped/retiring row opens no fullscreen input hole |
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
- **Desktop publication:** expose a reactive, plain presentation record from each
  `NotificationEntry` and a popup-record projection from `NotificationService`.
  Publish coherent content after each `sync()`/`post()` update, and pause changes,
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
and exposed viewport → ShellBorder registry/shader → desktop input region →
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
One animated row extent drives the column, stack viewport and body: the desktop wrapper disables the
Rollout's additional size morph. Expanded text cannot precede its painted body.
Overflow removes the departing row's actual height progressively with the shift,
not a collapsed-height estimate removed at arrival. Survivors are laid out before
the completed shift is cleared. The shader formulas and origin-wall endpoint
remain unchanged. Current desktop runtime evidence is recorded in spec 04; it
does not establish visual acceptance.

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
Expiry remains a host removal here; timer policy is checked in the desktop provider.
Focused
QML integration coverage lives in `tests/units/tst_NotificationStack.qml`.

The desktop now publishes plain records from its shared `NotificationStore` and
hosts this production stack through `NotificationPopupStack`. Its
`NotificationService.notify(summary, options)` API and the store remain desktop
policy; notification creation and importance stay outside this library. The
isolated desktop story instantiates the same store and production wrapper, with
focused flows for replacement, expiry, overflow, retention, fullscreen masks
and reset cancellation. Its expanded-dismiss readiness check compares actual
card, stack, rollout and registry geometry rather than only the card's local
expansion flag. Production compositor-fullscreen flows exercised hover/expand,
same-ID replacement, middle-dismiss, hover expiry pause/resume, keyboard and
outside-click delivery with popup containment. The native content/fade capture
averaged about 25 fps, sufficient for this simple motion; it is not 60 fps.

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
the first two; the desktop flow observes the full geometry handoff. No new
visual direction, type scale, responsive layout or tokens are proposed; those
design steps retain the current component decisions. Existing production runtime
flows cover earlier desktop lifetime and fullscreen input paths; they do not
verify this revised content/action composition. Owner review remains pending.
expected: same-ID replacement keeps one card current; destroyed sources leave no
render references; last content and dimensions survive retreat, then release;
retiring rows accept no input or hover retention; removing a hidden presentation
changes no visible border. Runtime checks and owner review establish outcomes,
not source review alone.
