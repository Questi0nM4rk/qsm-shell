# Backlog

Open items only. Finished work lives in git. One line per item; a line that
needs a paragraph is a design question for the owner, not a backlog entry.

## Next

- Unit migration is at 19 of 51 types; 23 remain. `node scripts/workbench.mjs
  --check --provider .` prints the count and names nothing missing, so the
  catalog is the checklist. Each one is a `workbench/units/<Type>.qml`, its
  story keys repointed, and a flow that drives it.
- The adapter puts a unit's `eventRecorder` kind into the harness's `origin`,
  but a flow may only assert `component|injected|route`, so a unit that records
  `"intent"` can never be asserted and 19 units record `"component"` to route
  around it. Fix the mapping and the units together; the deleted host kept kind
  and origin apart.
- `scripts/validate-library` lints `workbench/*.qml` and never
  `workbench/units/*.qml`, so a unit with a broken import passes the gate.
- `KeyValueRow` does not re-lay out when `icon` is filled in after construction:
  the label stays at x=0 under a visible 16px glyph. Built with the icon it sits
  at x=24, so the component is right and only the late change is stale.
- `SpinBox` host value goes stale after a native step: after `increase()` the
  component reads 43 while the host still reads 42.5 until the next write.
- ADR 0002's four decisions, in the order they unblock each other: one
  provider-owned keep-open type taking a pointer (deletes the rail's copy and
  the workbench mock's), `StateLayer` assertable state, `ScenePointer`
  overridable by a pointer-shaped object, `Rollout` sized by its owner. Then
  caelestia's `TransformWatcher` for the three `mapToItem`-in-a-binding call
  sites, and the comments defending that hazard can go with it.
- The shell's own flow host is gone; the harness owns the state machine. A
  composition flow still cannot pass, because the composition interpreter is a
  provider contribution and no provider here has one.
- `Rollout` cannot be the PARENT of a nested rollout, so the consumer's
  `BarPopouts` keeps its own keep-open predicate. The travel triangle is a
  geometric no-op while the popout is flush with a full-height band; nobody
  has checked whether flushness fails in some state.
- Popup family (`Menu`, `Popover`, `Dialog`, `ToolTip`) stays hand-rolled:
  `T.Popup` inside a `PanelWindow` paints only inside the window rect.
- Provider stories still need live owner review after adapter changes; keep
  behavioural regressions in component tests, not provider shape tests.
- From the consumer: `NotificationCenter` needs a deterministic tie-break
  between app groups (alphabetical vs recency, owner chooses); `Segmented`
  may want one gliding indicator instead of a fill per cell (`ui-design` and
  live judgement first); a compact CPU/memory readout is composed from
  `Stat`, `Meter` and `Prose`, never a new type.
- Types with no consumer yet: `Dialog`, `Scrim`, `Skeleton`, and `Popover`
  used as a tooltip or menu. Wait for a surface that needs them.
- Popup family (`Menu`, `Popover`, `Dialog`, `ToolTip`) stays hand-rolled:
  `T.Popup` inside a `PanelWindow` paints only inside the window rect.
- Provider stories still need live owner review after adapter changes; keep
  behavioural regressions in component tests, not provider shape tests.
- From the consumer: `NotificationCenter` needs a deterministic tie-break
  between app groups (alphabetical vs recency, owner chooses); `Segmented`
  may want one gliding indicator instead of a fill per cell (`ui-design` and
  live judgement first); a compact CPU/memory readout is composed from
  `Stat`, `Meter` and `Prose`, never a new type.
- Types with no consumer yet: `Dialog`, `Scrim`, `Skeleton`, and `Popover`
  used as a tooltip or menu. Wait for a surface that needs them.

## Left standing by the owner

- `volume` glyph sits 0.68px left of its muted sibling; offset 0 chosen.
- `Popover.qml`'s comment says "held", the word rejected on `Rollout`.

## Later

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
