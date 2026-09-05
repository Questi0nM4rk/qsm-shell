# Backlog

## Next

- **Port the existing qsm-desktop edge shader unchanged**, then render one
  `ShellBorder` with one dynamically anchored rollout, and review THAT live
  before adding nesting, welding, resizing or fullscreen rules.

  The consumer's `Rollout` (`qsm-desktop/shell/components/Rollout.qml`, ~390
  lines) is the thing to lift, and it is the last real duplication between the
  two repos. What makes it hard: it registers its live silhouette rect and its
  hit rect into two registries owned by `EdgeScene`, which feed a single
  full-screen SDF fragment shader per monitor. Lifting the rollout means
  lifting the scene, the registries and the shader with it — that is the
  `ShellBorder` system, not a component, and it wants an owner decision before
  any code.

  One rule it already carries and the library will need:
  `contentCenterOffsetX/Y`. A rollout is the band BULGING, so content that
  centres itself has to centre in body+band; centring in the body alone puts
  it half a band-depth off, every time, on every rollout.

- **`ScrollArea` still has no consumer** (`ScrollCue` has one: the cheat
  sheet). Eight surfaces in qsm-desktop still
  hand-roll a Flickable + a clip + a bar somebody drew + a fade somebody else
  drew: `ColorPickContent`, `RailAppList`, `LauncherSurface`, `ThemeCarousel`,
  `WorkspacesTab`, `NotificationCenterTab`, `ClipboardSurface`,
  `CheatSheetSurface`. Migrating them is the check on whether the component is
  actually right; until one uses it, it is a guess.

- **`Dialog`, `Popover`, `Scrim`, `Skeleton`, `Avatar` and `Sparkline` have no
  consumer either.** Each was built against a hand-rolled equivalent in
  qsm-desktop (`ModalHost`, `BarPopouts` + `PopoutController`, the session
  backdrop, the dashboard and performance tabs). Same rule: the migration is
  the proof — and it is not a formality. Every component migrated so far
  turned out to be missing a rule the hand-rolled version had learned:
  `ScrollCue` was reading `contentY` instead of `visibleArea` and had no cap
  on the mark's length, and `StatRing` could not draw a partial arc at all.

- **`Popover` is placement, not a tooltip and not a menu.** Its own header now
  says so. Building either of those over it is real work — focus entry and
  return, keyboard activation, whether the content is reachable at all — and
  it should wait for a surface that needs one rather than being guessed at.

## Later

- Decide whether the divider needs vertical orientation after a real layout
  requires it.
- Add SVG aliases and validation only when the first naming conflict appears.
- Add a light theme only after its palette is designed and reviewed.

## Known Environment

- `/usr/bin/qmltestrunner` is Qt 5 and cannot test this Qt 6 module. **The Qt 6
  one is at `/usr/lib/qt6/bin/qmltestrunner` and works**, including real
  `mouseClick` / `keyClick` under `QT_QPA_PLATFORM=offscreen`. The note above
  used to read as "this repo cannot have interaction tests", which is why it
  had none for months. `tests/interaction/` uses it, and `scripts/validate-library`
  runs it.
- Use `/usr/lib/qt6/bin/qml` with an explicit QML file and
  `QT_QPA_PLATFORM=offscreen` for native checks that are not TestCases.

## Measured Qt quirks

Each cost real time once. None is findable by reading the code.

- **`Keys.onPressed` accepting an event does NOT stop the per-key handler.**
  `Keys.onPressed` and `Keys.onDownPressed` hang off the same attached object,
  and setting `event.accepted` in the generic one does not suppress the
  specific one. A field carrying both moved a launcher list two rows per
  keystroke. Use ONE dispatcher.
  `tests/interaction/tst_textfield.qml` keeps that bug.
- **A `Flickable`'s declared children go into its `contentItem`.** They scroll
  with the content, and they count toward `childrenRect` — so chrome sized
  from the content is a binding loop. Chrome is a sibling of the viewport,
  never a passenger in it.
- **`Flickable.contentData` is not aliasable.** A wrapper needs a named `Item`
  inside the viewport and aliases that instead.
- **Qt clamps a rectangle's radius to half its SHORT side.** A 3px rule flush
  against a 12px-radius card cannot curve with it and pokes out at both ends;
  the container has to clip.
- **`Qt.application` has no `activeFocusItem`.** `Window.window.activeFocusItem`
  does, which is what `Dialog` reads to know where to send focus back.
- **A ternary yielding `undefined` does NOT withdraw an anchor.** Qt still
  sees `left`, `right` and `horizontalCenter` all declared on one item, warns
  every run, and resolves the conflict however it likes. One item that has to
  work in two orientations states its own rectangle instead.
- **A Rectangle paints its own fill and border BEHIND every child.** An opaque
  child filling the parent hides the parent's border completely; a selection
  ring has to be the last child, not the root's `border`.
- **A Rectangle with a radius and `layer.enabled` does not mask its children.**
  Item clipping is rectangular. A round photograph needs a real
  `MultiEffect.maskSource`.
- **Rotating a rectangle rotates it about its CENTRE.** A `w x h` strip turned
  90 degrees has `h x w` bounds displaced around that centre — set a
  Gradient's `orientation` instead of rotating the item that carries it.
- **`Keys` has no `onHomePressed` / `onEndPressed`.** Only the arrows, Return,
  Enter, Escape, Space, Tab, Backtab, Delete and the digits get named
  handlers; everything else needs a key check inside `Keys.onPressed`.
