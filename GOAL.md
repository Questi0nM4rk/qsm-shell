# Production Goal

Deliver `qsm-shell` as the complete local component library for one
`qsm-desktop` user: simple, minimal, fluid, and visually coherent in a real
Wayland window. Finish the components the desktop uses before speculative
types. The user judges the final result in the live window; workbench is the
main driver for every other check.

## Product Bar

A production-ready component is reusable QML with a small explicit API,
host-owned state, real pointer/keyboard/wheel/focus behavior, all meaningful
states, stable natural geometry, semantic `Style` tokens, and a focused
workbench composition or story. It is not done because it parses, captures, or
looks plausible in isolation.

- Dynamic: interaction responds immediately and motion explains a state change.
- Keyboard/API parity: every interactive operation has a public function listed
  in `actions`. Pointer, keyboard and external callers use that same function;
  keyboard focus/navigation must be reachable, not merely declared. Static
  readouts need no invented actions.
- Quiet: whitespace and surface elevation establish hierarchy; accent denotes
  selection, focus, or the primary action, never passive decoration.
- Durable: one concept has one type; slots hold caller content; no surface-
  named duplicate components or desktop policy in the library.
- Local: do not add compatibility layers, public-versioning work, generic web
  abstractions, documentation history, or coverage-driven tests.

## Scope

The production target is every library component used by the owner's desktop,
including internal component dependencies. Workbench demonstrates and hosts
review of this set; it is not a runtime dependency of the library. Inventory
comes from production `../qsm-desktop/shell/` declarations, excluding
`shell/preview/`, plus the dependency closure inside the library.

### Direct desktop use — 27 types

| Family | Components | Representative desktop consumers |
| --- | --- | --- |
| Frame and reveal | `ShellBorder`, `Rollout`, `ScenePointer` | `screen/EdgeScene.qml`, `components/ModalHost.qml`, rail, panel, OSD |
| Input and actions | `StateLayer`, `ArmedAction`, `ActionTile`, `Capsule`, `IconButton`, `TextField`, `Slider` | rail actions, session, search fields, sound, OSD, media |
| Rows and scrolling | `ListRow`, `ScrollCue` | `components/PopoutRow.qml`, `components/ResultRow.qml`, launcher, clipboard |
| Notifications and calendar | `NotificationStack`, `NotificationCenter`, `MonthCalendar` | notification popups, notification panel, rail calendar, dashboard |
| Readouts and identity | `Badge`, `Avatar`, `ColorSwatch`, `Meter`, `StatRing`, `Sparkline`, `Kbd` | rail, dashboard, performance, colour picker, cheat sheet |
| Visual foundations | `Card`, `Divider`, `EmptyState`, `Prose`, `SvgIcon` | panel cards, theme cards, lists and shared desktop composition |

### Internal dependencies — 4 additional types

- `ControlLabel` through `Slider`.
- `NotificationCard` through `NotificationCenter` and `NotificationStack`.
- `SelectionMark` through `ListRow` and `NotificationCard`.
- `Surface` through `ActionTile` and `TextField`.

This gives 31 component types in the current personal production scope.
Shared `Style`, `Tokens`, `Motion`, `Interaction`, icons, the edge shader and
`fuzzy.js` are supporting runtime dependencies, not extra component entries.
Reconcile this inventory when desktop use changes. Other catalog types enter
the production scope when the desktop needs them.

### Production readiness for the owner

Each in-scope type must work through its actual desktop composition, answer
its host correctly, and have an inspectable workbench example using the real
component. Its component record names the supported inputs, states, sizes,
overflow behavior, motion and reduced-motion behavior. Internal dependencies
may be accepted through their visible parent composition.

Readiness requires owner acceptance of the relevant behavior and appearance,
with known blocking defects resolved. Record source review, explicitly requested
runtime checks and owner acceptance separately; catalog presence is not acceptance.
Prepare and revise one selected item at a time under `AGENTS.md`, preserving
prior acceptance evidence rather than assuming every component starts over.
`docs/BACKLOG.md` holds remaining open work. The roadmap below owns the order
and exit criteria for this production scope.

### Active priority — shell readiness and desktop integration

Treat Workbench as the existing delivery tool, not another product to redesign.
Finish concrete shell defects and its desktop input/action/host integration
before desktop-only improvements. Preserve accepted component reviews; do not
restart the whole catalog. The roadmap groups below locate work, not permission
to expand this active scope.

The desktop action menu must be able to expose the same operations as pointer
surfaces: network items and Wi-Fi setup, Keep awake, Night light and other
desktop controls. The immediate goal is easy keyboard control through the action
menu and reachable keyboard navigation throughout the desktop. Reuse existing
service functions or the same external command; invoking the existing Wi-Fi
listing command from another caller is sufficient. Do not require a universal
backend API, new daemon or wholesale extraction of view logic to achieve this.
Share operation logic where another caller actually needs it; focus, selection
and presentation-only filtering/sorting may remain in the frontend.

Components are controlled frontends: report intent, render host-owned state and
expose local interaction actions without synthesizing input. Those component
functions describe UI interaction; they are not the desktop's backend API.
Desktop operations use existing service/tool entry points without constructing
their pointer frontend. Reuse command-centre routes and prefer named function
dispatch; extract new shared code only for a concrete duplication or blocker.

Keyboard UX preserves the person's place: repeatable activation keeps the same
item selected; value items reveal a horizontal Slider directly beneath that item.
Enter/Escape returns from the editor to the same item with the applied value.
Slider arrows remain available alongside shared configurable decrease/increase
keys, N/O by default. These bindings never consume text typed into search.

For each selected item, close keyboard reachability, callable actions, host
responses, availability and actual result reporting together. A transient popup
must not steal focus: its component supports keyboard input in a focus-capable
host, while the desktop provides an explicit keyboard route to the operation.
Broader desktop polish and features follow shell readiness. Requested runtime
checks and owner acceptance remain separate from source readiness.

## Current evidence

All 31 types have implementations and provider units; the whole library catalog
contains 59 stories. Static review covered the production implementations,
desktop consumers and provider units in three bounded research groups.
This establishes availability and identifies work, not visual or runtime acceptance.

The owner confirms review of the original 31-type production set is complete;
do not repeat its review-only queue. This does not close the concrete repairs
below or accept the newly requested DataCapsule and fullscreen host compositions.
Historical evidence also includes
57 workbench tests and the three desktop rail flows (61/49/64 steps), retained in
`/tmp/opencode/desktop-input/final-*.log`. Those results predate later UI/event
changes and do not establish runtime correctness of subsequent repairs.

The remaining effort is finite integration repair and owner review, not a new
component catalog or a new workbench. There is no defensible completion percentage
or elapsed-time estimate until the concrete repairs and owner feedback are closed.

## Ownership

| Concern | Owner |
| --- | --- |
| Reusable components, intent APIs, style/motion, assets and shader | `qml/QsmShell/` |
| Story state, meaningful fixtures, controls and desktop-shaped cases | Library `workbench/units/`, `Adapter.qml`, compositions and catalog |
| Window, generic inspection, native driver and flow engine | Sibling `qsm-workbench` |
| Services, persistence, compositor masks, focus policy and real view wiring | Sibling `qsm-desktop/shell/` |

The provider owns its theme installation; the generic harness does not acquire
desktop palette/service policy. Native simulation is opt-in, not a prerequisite
for a manually reviewed story. Static types do not need a synthetic action API
or a flow just to qualify for release.

## Source Hierarchy

1. `AGENTS.md` is the binding component law and measured Qt/Wayland reality.
2. `design-system-blueprint.pdf` supplies the visual floor: semantic tokens,
   4px rhythm, one typography and icon scale, designed states, purposeful
   motion, and usable targets.
3. `../Clonned/caelestia/repo/components/controls/Styled*.qml` is the primary
   QML reference. Copy proven template wiring, geometry, and interaction
   mechanics, then translate them to this library's `Style`, tokens, and
   host-owned-state contract. Do not copy Caelestia services, palette globals,
   surface policy, or unrelated features.
4. `ui-design`, `ux-audit`, and `ui-audit` provide the design and live review
   method. A visual decision must resolve to an existing token or a deliberately
   added token.

## Roadmap

Order is by shared dependencies and consequence. Each milestone contains several
small owner-selected items; it is not permission to implement a whole group or
advance past a review. R0 enables motion review. R1-R4 close the component set;
R5 requires them all. Reuse accepted evidence rather than restarting the rail.

### R0 — Make the existing preview sufficient for production review

First item: one provider-owned theme/reduced-motion control, demonstrated on an
existing animated story. `workbench/Adapter.qml` and its units currently install
no `Style.backend`; `Style.qml:24` defaults reduced motion to false. The README's
claim that stories use `workbench/theme.json` is not backed by this launch path.
Keep library defaults available and make the chosen preview environment explicit.

Exit: the owner can compare normal/reduced motion on the same real component,
reset the preview predictably, and identify which theme is in use. Desktop
effects/compositor behavior remain a separate real-window check. Complete only
the scale/Events follow-up that actually blocks judging this item.

### R1 — Close notification lifecycle and history behavior

Order: `NotificationCard` → `NotificationStack` → `NotificationCenter` with
the desktop service adapter. These are the highest-consequence open paths.

- `NotificationCenter.qml:169-181` sorts the caller's array in place with an
  empty query; preserve host ownership. Its group tie-break is still an owner
  decision in the backlog.
- `NotificationCenterTab.qml:30-33` drops dismiss requests for archived rows,
  whose records lack `notificationId` (`NotificationService.qml:246-253`).
  Make the offered removal operation truthful, including persistence.
- `NotificationStack.qml:169-171` renders live objects despite its snapshot
  contract, while `NotificationService.qml:214-223` removes and destroys them.
  Resolve the lifetime contract before claiming the animation is production-safe.
  A crash is NOT reproduced by this source review; replacement, hover pause and
  service callbacks must remain correct if the model changes.
- `NotificationCard.qml:113-123` derives relative age from `Date.now()` without
  a ticking dependency; an unchanged expanded card has no scheduled age refresh.

Exit: arrival, overflow eviction, replacement, expiry, hover pause, dismissal,
empty stack, history search/removal and action invocation have truthful outcomes;
the owner accepts their reveals/reflows and reduced-motion behavior. Use one
selected fixture at a time; service integration cannot be proved by a fake callback.

### R2 — Close controls, selection and host responses

Order: shared unavailability (`ListRow`, `IconButton`, `StateLayer`) →
`Slider`/`ControlLabel` → `TextField`/`SelectionMark` →
`ArmedAction`/`ActionTile` → `Capsule`.

- `ColorPickContent.qml:403` uses `enabled`, but ListRow paints unavailability
  from its separate `disabled` property (`ListRow.qml:47,80,86`). Unify the
  offered state at the owning boundary; do not claim disabled Qt input activates.
- Dashboard previous/next buttons only change opacity
  (`DashboardTab.qml:275,289`), unlike MediaTab's proper `enabled` binding.
- Three hover-only rail entries still default to clickable with no action
  (`Rail.qml:214,224,242`, `RailEntry.qml:27`).
- `units/Slider.qml:41-51` exposes a clickable label but never answers
  `labelClicked`; the desktop OSD does. Make the fixture demonstrate that task.
- Add desktop-used compact/padded cases for Capsule/IconButton. Inspect session
  pointer/keyboard selection and armed feedback before changing ActionTile's API;
  a raw hover event alone does not prove the resting cursor stole selection.

Exit: enabled/disabled/report-only states agree with actual input; value changes,
commit, focus and confirmation routes reach the host; no action merely looks
successful. The owner accepts the control in its real compact composition.

### R3 — Close frame, navigation and view motion

Types: `ShellBorder`, `Rollout`, `ScenePointer`, `ScrollCue`, `MonthCalendar`, `Kbd`.
Preserve the accepted rail behavior; extend evidence to notification, panel,
OSD and modal geometry rather than redesigning the shared mechanism.

- Rail/workspace WheelHandlers (`Rail.qml:331`, `WorkspaceStrip.qml:131`)
  conflict with the recorded local Wayland limitation. Confirm the current live
  route when authorized and align the implementation; no fresh failure is claimed.
- Add the desktop-used horizontal ScrollCue case to its existing unit.
- `CheatSheetSurface.qml:248-259` clips long Kbd combinations inside a fixed
  column. Make complete combinations readable and expose a long case in its unit.
- Check calendar focus in BOTH the rail and dashboard. Hover-only access to the
  rail is not evidence that the entire desktop calendar is keyboard-inaccessible.

Exit: relevant reveal edges, nested travel, interrupted/reversed motion,
suppression, dismissal and scroll boundaries are accepted. Calendar month/year
changes and long key combinations remain usable. Actual Wayland masks and
cross-window focus need owner review; an offscreen flow cannot certify them.

### R4 — Close readouts, identity and visual foundations

First small item: correct desktop icon names that resolve to missing assets.
`LauncherSurface.qml:56,59,60,216,218` requests `panel`, `trash`, `eyedropper`,
`refresh`, `network`; `ResultRow.qml` forwards them to SvgIcon's filename lookup,
and those files are absent from the bundled icon directory.

Then review `Avatar` photo/artwork with fallback (the unit currently has no
source), `ColorSwatch` compact palette and repeat-copy feedback, and live
`Meter`/`StatRing`/`Sparkline`/`Badge` changes. Include empty/startup data, not just
populated samples. The accent row's preferred footprints exceed available width;
inspect layout resolution rather than claiming a measured pixel overflow.

Finish `Card`, `Divider`, `EmptyState`, `Prose`, `SvgIcon`, `Surface` through
their real parent views. Expose desktop-relevant cases only. Card radius overrides
are an owner consistency decision, not automatically illegal; Surface focus is
host composition, so align its record without inventing a second focus mechanism.

Exit: names/icons/readings agree, missing sources and empty values are legible,
supported sizes and long content fit, and changing data/motion remain calm. The
owner accepts the relevant visual cases; static types need no ceremonial flows.

### R5 — Accept the integrated personal production set

Prerequisite: R0-R4 exit evidence is recorded for every in-scope type, either
directly or through an accepted parent. Each component record says what was
accepted, which consumer configuration it covers, and any remaining limitation.

Prepare one real desktop view at a time: rail/popouts + OSD, launcher/clipboard
rows, notification popup/history, panel data/media/calendar, session/cheat sheet.
Repair cross-view defects revealed there in the owning component or adapter.
Read-only probes finishing after dismissal need an explicit lifecycle policy;
intentional copy/action work must not be cancelled just because a view closed.

Exit: no known blocking defects in these production paths; workbench can show
the accepted views/states using the real components; the desktop runs without
workbench. When requested, perform the small real-input/service/shader checks
needed for unresolved concerns and record their actual revision and results.
Preserve the current local checkout/import arrangement for this personal goal;
public packaging or a clean-machine distribution exercise is a separate request.
Committing/releasing changes still requires the owner's instruction.

## Per-component review queue

Every row has implementation and a workbench unit. "Review" means no concrete
blocker established in this source pass, NOT production acceptance. "Repair"
names a grounded library/consumer issue. "Fixture" names an unavailable review
case, not a broken production component. R0's motion-mode gap applies across rows.

| Component | Remaining work / evidence | Milestone |
| --- | --- | --- |
| ShellBorder | Review other host shapes/masks; rail evidence already exists | R3 |
| Rollout | Rail scenario accepted; review other reveal sizes/edges and interruptions | R3 |
| ScenePointer | Review mapped regions and retention through actual view hosts | R3 |
| StateLayer | Review inherited disabled, hover-only and parent-owned focus paths | R2 |
| ArmedAction | Review timeout/leave/cancel/repeat through quick-action host | R2 |
| ActionTile | Review session keyboard/pointer ownership and visible armed state | R2 |
| Capsule | Fixture: desktop `sm` case; review input and disabled state | R2 |
| IconButton | Repair dashboard availability; fixture compact/padded cases | R2 |
| TextField | Review search/edit/focus/long input in real row hosts | R2 |
| Slider | Fixture: answer label click; review wheel, drag, commit and OSD use | R2 |
| ControlLabel | Accept through Slider's label routes and geometry | R2 |
| ListRow | Repair unavailable-state mismatch; review trailing slot and long text | R2 |
| SelectionMark | Accept selection/expansion feedback through ListRow/NotificationCard | R2 |
| ScrollCue | Fixture: horizontal desktop scroll; review fitting/overflow boundaries | R3 |
| NotificationCard | Repair live age refresh; review expand/dismiss/action/archived states | R1 |
| NotificationStack | Resolve live-object/snapshot lifetime; review replacement/eviction/retract | R1 |
| NotificationCenter | Repair input-array mutation and desktop archived removal; decide tie-break | R1 |
| MonthCalendar | Review both consumers, reachable focus, paging and year rollover | R3 |
| Badge | Review empty presence, reading, tone and state transitions | R4 |
| Avatar | Fixture: photo/artwork and missing source; review mask/ring/fallback | R4 |
| ColorSwatch | Review palette fit, alpha/contrast and repeat-copy result | R4 |
| Meter | Review live value/empty endpoints and relevant axis under the host | R4 |
| StatRing | Review changing fractions, desktop sizes and content fit | R4 |
| Sparkline | Fixture: startup empty/one point; review live/flat series and scales | R4 |
| Kbd | Repair consumer clipping; fixture long combination | R3 |
| Card | Review dashboard/performance variants; resolve radius intent if inconsistent | R4 |
| Divider | Fixture desktop rule configurations; review in their parent view | R4 |
| EmptyState | Review actual title-only/long/degraded desktop messages | R4 |
| Prose | Review used roles, long labels and numeric readings in context | R4 |
| SvgIcon | Repair requested missing asset names; review tint/size in real rows | R4 |
| Surface | Accept through TextField/ActionTile; align focus wording in record | R4 |

## Execution contract

Choose one item from the next milestone, prepare it, report its purpose and
reachable states, then wait for owner feedback. No automatic advancement or
self-acceptance. Run or add tests, captures, validation or desktop input only
when explicitly requested; use workspace 10 when operation is authorized.
Read the current component record and consumer before changing behavior. Keep
records current rather than adding decision histories. Follow current user
model choices, preserve all dirty work and unrelated worktrees, and do not commit
or restart the owner's review window without instruction.
