# Backlog

Open items only. Finished work lives in git. One line per item; a line that
needs a paragraph is a design question for the owner, not a backlog entry.

## Next

- `TextField`: release. Open audit lines: the 1px failed border and 1px focus ring render unevenly at dpr 1.2 (top
  6.07:1, side 4.03:1); slot glyphs 20 and 16 in one row; leading glyph
  ignores `size`; trailing padding survives an emptied slot; caret lands on
  fractional x; disabled dims text, leading and trailing glyph in three
  different steps; search leading action is a 20x20 target.
- `Slider`: the resting track is `Style.outline`, about 1.9:1 against the
  shell background; a dedicated track token is the owner's call. Hosts set
  `wheelUnits` per surface (a seek bar 0, a level bar the keyboard units).
- `MonthCalendar` takes the wheel with a `WheelHandler`, so it is dead in a
  live window and pages a month per any nonzero delta. Fix at its migration.
- `Rollout` cannot be the PARENT of a nested rollout, so the consumer's
  `BarPopouts` keeps its own keep-open predicate. The travel triangle is a
  geometric no-op while the popout is flush with a full-height band; nobody
  has checked whether flushness fails in some state.
- Popup family (`Menu`, `Popover`, `Dialog`, `ToolTip`) stays hand-rolled:
  `T.Popup` inside a `PanelWindow` paints only inside the window rect.
- Remaining types move to `previews/units/` in this order: `Switch`, `Checkbox` plus `Radio`, buttons on `T.AbstractButton`,
  `SpinBox`, `Segmented` on `T.TabBar`, `ScrollArea` on `T.ScrollBar`, then
  the rest. Every type moved so far surfaced a real defect (no keyboard
  route, no Tab stop, hover while disabled, truncated natural width); budget
  for fixing what the move surfaces.
- `ListRow`: a report-only row (`interactive: false`) dims exactly like a
  disabled one, against the law it carries (changes the desktop look, owner
  judges); an empty trailing slot takes space (`RowLayout` spacing with no
  gate on children).
- From the consumer: `NotificationCenter` needs a deterministic tie-break
  between app groups (alphabetical vs recency, owner chooses); `Segmented`
  may want one gliding indicator instead of a fill per cell (`ui-design` and
  live judgement first); `ColorSwatch` needs its painted sample separated
  from its pointer target to meet the 44px floor; a compact CPU/memory
  readout is composed from `Stat`, `Meter` and `Prose`, never a new type.
- Types with no consumer yet: `Dialog`, `Scrim`, `Skeleton`, and `Popover`
  used as a tooltip or menu. Wait for a surface that needs them.

## Left standing by the owner

- `volume` glyph sits 0.68px left of its muted sibling; offset 0 chosen.
- The preview control strip marks the last option clicked, not the state the
  unit is in; `call` options have nothing to compare against.
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
- **A `HoverHandler` forces `acceptHoverEvents` on its item even while
  disabled**, and `hoverEnterEvent` sets `hovered` from `hoverEnabled`.
- **`setValue` refuses a write fuzzy-equal to the current value**, so a
  `stepSize` whose multiples cannot express a bound saturates below it (0.1
  lands on 0.9999999999999999, 0.01 lands on 1).
- **Qt reports positive `angleDelta.x` when the top of the wheel goes left**
  and does not consult `event.inverted`.
- **`QT_QUICK_BACKEND=opengl` does not exist.** The RHI backend is
  `QSG_RHI_BACKEND`.
