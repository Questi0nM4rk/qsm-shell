# Backlog

Open items only. Finished work lives in git. One line per item; a line that
needs a paragraph is a design question for the owner, not a backlog entry.

## Next

- Shell readiness first: close concrete component defects and keyboard/public-action
  parity through desktop hosts and the existing action menu; defer desktop-only
  improvements and Workbench polish unless they block the selected item (`GOAL.md`).

- ListRow's additive headingHeight/expansionHeight contract is source-prepared for desktop inline audio; live consumer sizing awaits the current desktop item review. The owner approved shell Compositions / menu-items for that adoption.

- Rollout: all attached desktop callers' appearance and smooth motion are owner-accepted; generic sound-settings variants and spec completion remain open under `openspec/changes/rollout-expansion`.

- DataCapsule's watched appearance is owner-accepted; production compositor-
  fullscreen notification/OSD geometry and input are exercised. Audio/brightness
  mutation routes and unrelated capsule compositions are outside that evidence.
- Desktop CPU/memory readings need a DataCapsule composition with persistent or
  event-driven visibility and an explicit open action, without library service policy.

- Personal production scope is the 27 directly used desktop components plus four
  internal dependencies listed in `GOAL.md` (31 types). Reconcile existing component
  acceptance evidence against its R0-R5 roadmap, then prepare one selected item at a
  time; catalog/flow presence alone is not acceptance.
- R0: provider installs no `Style.backend`, so reduced motion defaults to false and
  README's `workbench/theme.json` claim is unsupported; add a provider-owned review
  environment, deferred to the first selected implementation item.
- R1: NotificationStack lifetime and production fullscreen input are exercised;
  the watched capsule appearance is owner-accepted. Recording cadence guidance
  distinguishes actual capture rate from CFR encoding in `AGENTS.md`.
- R1: `NotificationCenter.qml:169-181` mutates the host array during sorting and
  `NotificationCard.qml:113-123` has no ticking age dependency; deferred beyond
  the selected NotificationStack lifetime item.
- R2/R3: Slider's unit does not answer label clicks; compact Capsule/IconButton,
  horizontal ScrollCue and long Kbd cases are missing from their review controls.
  Extend existing units with their owning milestone, not a new catalog or flow suite.
- R4: include startup empty/one-point Sparkline data and real desktop Divider cases;
  align Surface's focus wording with host composition. Deferred to those view reviews;
  lack of a flow for a static component is not itself a defect.
- Sibling workbench `BRIEF.md` retains mandatory tests/commits inconsistent with current
  rules. Deferred to harness docs; library roadmap and brief use the owner-led contract.
- Native simulated input is currently wired in the desktop provider, not this library's
  `workbench/Adapter.qml` (no `inputDriver`/native targets). Live component demos and
  semantic actions are separate capabilities. Defer native target exposure until a
  selected library story needs it; it is not a prerequisite for a manual animation demo.
- Owner review of uncommitted component/provider changes: one item at a time,
  tests only when requested; preserve unrelated worktrees.
- Quiet Luminous review: prepare a coherent task, then owner checks pointer,
  keyboard, focus, sizes, overflow and states; fix the same item until accepted.
- `ActionTile`, `Segmented` and `ColorSwatch` fixtures need owner review of
  purpose, glyph/copy consistency and reachable supported cases before continuing.
- Provider migration and native inspection are available, but component-wide
  owner acceptance is still open; a desktop rollout trace does not establish it.
- Popup family (`Menu`, `Popover`, `Dialog`, `ToolTip`) stays hand-rolled:
  `T.Popup` inside a `PanelWindow` paints only inside the window rect.
- From the consumer: `NotificationCenter` needs a deterministic tie-break
  between app groups (alphabetical vs recency, owner chooses); `Segmented`
  may want one gliding indicator instead of a fill per cell (`ui-design` and
  live judgement first); a compact CPU/memory readout is composed from
  `Stat`, `Meter` and `Prose`, never a new type.
- Types with no consumer yet: `Dialog`, `Scrim`, `Skeleton`, and `Popover`
  used as a tooltip or menu. Wait for a surface that needs them.
- Avatar's image/mask route needs a photo fixture and live review; initials
  and glyph fallback stories do not exercise image loading.

## Left standing by the owner

- `volume` glyph sits 0.68px left of its muted sibling; offset 0 chosen.
- `Popover.qml`'s comment says "held", the word rejected on `Rollout`.

## Later

- Public distribution, if requested: obtain clean-checkout evidence for the
  installed Workbench preview setup before promising an independent public package;
  not a gate for personal use.
- Workbench narrow Controls inspector can clip lower action rows; track the
  harness limit in its README;
  resume only if it blocks component work, not as a standalone polish project.
- Vertical `Divider` when a layout needs it. SVG aliases at the first naming
  conflict. A light theme after its palette is designed.

## Measured Qt quirks

Each cost real time once. None is findable by reading the code.

- **`clip: true` shaves a child's hover growth.** A control that grows on
  hover cannot sit inside a clipping ancestor sized to it.
- **A `Rectangle` radius does not round its children, and `clip` does not
  either.** Item clipping is rectangular; `MultiEffect.maskSource` is the only
  mechanism that cuts corners. `layer.enabled` does not help.
- **`Keys.onSpacePressed` needs focus, and nothing gives it by default.** Key
  handlers without `activeFocusOnTab` and without focus on press are a
  keyboard path that cannot be reached.
- **`Keys.onPressed` accepting an event does NOT stop the per-key handler.**
  Both hang off the same attached object. Use ONE dispatcher.
- **`Keys` has no `onHomePressed` / `onEndPressed`.** Only arrows, Return,
  Enter, Escape, Space, Tab, Backtab, Delete and digits get named handlers.
- **A `Flickable`'s declared children go into its `contentItem`** and count
  toward `childrenRect`; chrome sized from content is a binding loop. Chrome
  is a sibling of the viewport. `Flickable.contentData` is not aliasable;
  alias a named `Item` inside the viewport instead.
- **Qt clamps a rectangle's radius to half its SHORT side.** A thin rule
  flush against a rounded card cannot curve with it; the container clips.
- **`Qt.application` has no `activeFocusItem`.** `Window.window.activeFocusItem`
  does.
- **A ternary yielding `undefined` does NOT withdraw an anchor.** An item
  that works in two orientations states its own rectangle.
- **A Rectangle paints its fill and border BEHIND every child.** A selection
  ring has to be the last child, not the root's `border`.
- **Rotating a rectangle rotates it about its CENTRE.** Set a Gradient's
  `orientation` instead of rotating the item that carries it.
- **`visualPosition` on a slider node emits no change when orientation or
  mirroring flips**; a painted position names both as dependencies.
- **`T.RangeSlider` picks the pressed node by VALUE distance, not by handle
  geometry**, after a handle hit test that ignores `visible`. A parked node
  needs a sizeless handle, and a single-thumb press has to move the live
  node to the press point before Qt sees it.
- **`T.RangeSlider` makes each handle a tab stop and its `focusInEvent`
  hands focus to a handle.** Taking the stops away sends that hand-off in a
  circle until the stack is gone; keep them and read the handle's focus.
- **`T.RangeSlider` rewrites handle z on every press** (grabbed 1, other 0),
  so anything meant to paint under both handles sits at -1.
- **`T.Switch` writes `checked` itself on a drag release, even with
  `checkable: false`.** A click leaves `checked` alone and emits `clicked`;
  a drag past the middle sets it. A host-owned switch stands on
  `T.AbstractButton` and gives up drag. Space clicks a template button,
  Return does not.
- **A `HoverHandler` forces `acceptHoverEvents` on its item even while
  disabled**, and `hoverEnterEvent` sets `hovered` from `hoverEnabled`.
- **`setValue` refuses a write fuzzy-equal to the current value**, so a
  `stepSize` whose multiples cannot express a bound saturates below it (0.1
  lands on 0.9999999999999999, 0.01 lands on 1).
- **Qt reports positive `angleDelta.x` when the top of the wheel goes left**
  and does not consult `event.inverted`.
- **`QT_QUICK_BACKEND=opengl` does not exist.** The RHI backend is
  `QSG_RHI_BACKEND`.

## Agent task backlog (folded in from `.codeagent`)

The codeagent task files are gone; these lines are what they still say.
`SH-C3` is the only one the owner accepted, and none of the work is committed
until the current cleanup commits land.

- **SH-C1 Forward the shared preview environment** — implemented; composition
  boundary checks pass, story opt-in source-reviewed, runtime proof rides on
  SH-C3.
- **SH-C2 Shared mock screen and bounded placement** — implemented; the
  fixture's checks pass and the overlay does not crop external elevation. Owner
  judgement open.
- **SH-C3 Neutral capsule base on the mock screen** — implemented, **owner
  accepted**; the 53-step native base flow passes.
- **SH-C4 Real capsule composition container nodes** — implemented; real slot
  children, host-owned capsule state and shared placement verified, composition
  owner review open.
- **SH-C5 Real Slider sound-channel composition leaf** — implemented; actual
  Slider and mute-label input verified inside a correctly sized vertical
  capsule, owner review open.
- **SH-C6 Discoverable sound Compose and migrated flows** — implemented; the
  starter and the 28-step sound plus 57-step lifecycle flows pass. Live window
  evidence deferred to SH-C7.
- **SH-C7 Exact live base and Compose handoff** — live run on workspace 10 got
  as far as real pointer, keyboard, label mute and wheel routes; native F11
  compositor evidence still missing. Not accepted.
- **SH-C8 Neutral base control grouping correction** — declaration-only
  regrouping so independent choices are separate from commands; the migrated
  53-step flow passes, live review open.
