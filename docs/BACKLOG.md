# Backlog

## Next

### Preview/test migration underway (2026-09-08)

ADR 0001 accepted 2026-09-09: controls go on `QtQuick.Templates.Control`
with the `T.` types. Phase 0 items done: tree dump (`--inspect` flag on
preview and capture), actions walk in `tst_units`, `StateLayer` host mode,
`icon.lg` sized 24, GPL-3.0 licence, ADR 0001. `TextField` is the first type
at the definition of done (states, actions, design record, unit, test).

Every public type is getting its own `previews/units/<Type>.qml` proof
harness and its own `tests/units/tst_<Type>.qml` behaviour test, draining
`tests/interaction/tst_library.qml` one type at a time. Next types in order:
`Slider` (plus `RangeSlider`), `Switch`, `Checkbox` plus `Radio`, buttons on
`T.AbstractButton`, `SpinBox`, `Segmented` on `T.TabBar`, `ScrollArea` on
`T.ScrollBar`, popup family stays hand-rolled (spike 2026-09-09, see OPEN
entry below).

`ScenePointer` is a new type: a hover-position reader meant for an ANCESTOR
of the surfaces it watches. `Rollout` (ported from the consumer 2026-09-07,
see the `ShellBorder` entry below) gained the hover/trigger contract this
same run: `hoverAreas`/`triggerAreas` in, `hovered`/`keepOpen`/`triggered`/
`wantsOpen` out. Both got their first unit and test alongside the change.
The consumer `qsm-desktop` now depends on both: `EdgeScene.qml`,
`BarPopouts.qml` and the OSD/notification/panel/session surfaces all import
them.

OPEN, not investigated: the offscreen capture pipeline does not rasterise
`SvgIcon` glyphs. A blank where an icon belongs is the pipeline, not the
component, but it means every PNG check is blind to anything icon-shaped.

OPEN: a synthetic `mouseWheel` from QtTest does not reach a `WheelHandler`
under `--window` (real Qt6 Wayland QPA). Offscreen stays the only valid run
for wheel behaviour until this is understood.

OPEN, and one reason `BarPopouts` in the consumer is still NOT a `Rollout`:
`Rollout` cannot yet be the PARENT of a nested rollout. `BarPopouts` talks to
`registerBulge`/`unregisterBulge` directly instead of through a `Rollout`'s
`host` -- its comment names its own caelestia-derived clamp geometry as a
second reason, so this gap blocks it but is not the only thing that would.

OPEN, settled by spike: Popup spike 2026-09-09: T.Popup in a PanelWindow does
not paint outside the window's own rect; NoAutoClose held. Decision:
Menu/Popover/Dialog/ToolTip stay hand-rolled over Rollout/Popover.

Fixed in the same run, worth the record: `Slider` had no keyboard route and
no focus state at all, and a disabled `Slider` still reported `hovered`
(`tests/units/tst_Slider.qml` carries the coverage for both).
`ListRow.implicitWidth` reported its body's span while the body loses two
insets to its own margins, truncating text in the first caller that trusted
natural sizing. `QT_QUICK_BACKEND=opengl` was a value that never existed:
`QT_QUICK_BACKEND` only knows `software`, `d3d12` and `openvg`, and the RHI
backend Qt actually renders through is `QSG_RHI_BACKEND`, already set
correctly beside it.

### `TextField` migration -- CLOSED 2026-09-08

- [x] Move the public type to `previews/units/TextField.qml` and remove its
  inline search rendering from `previews/Preview.qml`.
- [x] Map `text-input`, `search`, `password-input` and `number-input` to the
  one type unit, with coherent glyphs and actions for every purpose.
- [x] Move behaviour coverage to `tests/units/tst_TextField.qml`, delete
  `tests/interaction/tst_textfield.qml` and drain `text2` from
  `tests/interaction/tst_library.qml`.
- [x] Exercise text typing/clear, search submit, password reveal, number
  validation, rest/hover/focus/failed/readOnly/disabled and sm/md/lg in native
  Wayland QML.
- [x] Run the focused test offscreen and on Wayland, capture all four scenario
  keys, run `qmllint`, `npm test` and `git diff --check`. Final suite: 121
  passed, 0 failed.

`TextField` gained the tab stop it lacked: the inner `TextInput` had
`activeFocusOnTab` false by default, so only a pointer click or
`focusField()` could reach it, and a keyboard-first surface had no way to Tab
into the field (`tests/units/tst_TextField.qml` pins both routes). Its public
`masked` boolean became `inputType` (`text`/`password`/`number`): password
stays masked with the hidden-input hints while being typed into and can be
revealed without ceasing to be a password, number rides a host-overridable
`validator` (any double, no
hardcoded range) and rejects letter keystrokes, and `accept()` — the
Return/Enter route — emits `accepted` only when `acceptableInput` is true, so a
host owns its own error copy instead of a component auto-failing the paint
(`tests/units/tst_TextField.qml` pins both).

The live unit found two more production defects. `StateLayer`'s accent focus
ring painted above the field's danger border, hiding failure while the field
was focused; `focusColor` now carries the stronger semantic state through the
ring. A full-field I-beam also overrode the hand cursor of slot actions;
`TextField` now routes cursor shape by region. The same live pass settled the
composition contract: plain text uses a type glyph and clear, search uses a
magnifier that calls the same `accept()` as Return plus clear, password uses a
key and eye/eye-off without dropping password semantics, and number uses a hash
and clear. `type.svg`, `key.svg` and `hash.svg` join the bundled Lucide set.

A live pass after that found the purpose switch was NOT glyph-swap only: the
leading slot had silently changed WIDTH. Plain text/password/number put a bare
24px `SvgIcon` in the slot, while search put an `IconButton` whose
`implicitWidth` is `size + 2*padding = 32px`, so the whole text column moved
8px right — and optically re-centring the search glyph (`glyphOffsetX`)
aligned the glyph while the TEXT stayed displaced, which reads as "one field,
two text starts". Rule: a slot action's layout footprint must equal the glyph's
own width; the pointer target stays the glyph-sized box and the surrounding
slots must never grow to fit a control's padding (`padding: 0` on the search
action, pinned by `tests/units/tst_TextField.qml`). Intrinsic widths of slot
children are column geometry, not decoration.

The same live pass that settled the caret settled two more owner-ratified
behaviours. A password field must mask EVERYTHING, including the character
being typed: `PasswordEchoOnEdit` revealed the whole text while the field was
being edited, and since the dots turned into letters under the caret, typing
looked like it had wiped the field (`tests/units/tst_TextField.qml` pins
always-mask and text preservation). And a text box's preferred width is a
CONSTANT, never content-derived: the first `implicitWidth` fed the input's own
implicit width into the sum, so typing stretched the box across the screen.
Long values now scroll inside the clipped column; the box reports one fixed
resting size. The stock caret lost both cases that matter -- it hides during
fast/held typing and, at the scroll edge of a long value, reads as a 1px smudge
next to the trailing action -- so `TextField` draws its own 2px accent caret
from `cursorRectangle`, always visible while the field has focus. The first
version pinned that caret flush at the scroll edge, and "flush" read as "under
the button": the row spacing alone was too little air. A full spacing inset
read as too far, so the owner's live ruler settled it: the scroll-end caret
should land where the text would in an endless box -- one row-spacing step
from the trailing action. The row's spacing is now `Style.space2` (one step
down from the box margin; both slot sides shrink together), and the input's
`rightPadding` is only as deep as needed to keep the whole 2px bar past the
clip (`Style.spaceTight`). `test_caret_clears_the_trailing_action` pins the
distance to the spacing step in both directions.
Scanning gotcha while verifying live: the 1px focus border produces a
continuous full-field accent run (top+bottom rows each hit the pixel
threshold), which reads as a "selection" in a naive accent-colour scan. To
find the caret, count accent hits PER COLUMN and keep only tall columns
(`>=8`): the border contributes ~2, the 21px caret contributes ~26.

### Component findings transferred from qsm-desktop -- 2026-09-08

Only the neutral mechanism moves here; desktop data, policy and compositor
integration stay with the consumer.

- `NotificationCenter` needs a deterministic tie-break between app groups
  that both contain a live entry. The current comparator can return equality
  and split one app's section around another. Implementation waits on the
  owner choosing alphabetical versus recency order.
- `Segmented` may need one indicator that glides between cells rather than a
  selected fill per cell. This changes every consumer's motion language, so it
  needs `ui-design` and a live owner judgement before code.
- `ColorSwatch` needs its painted sample size separated from its pointer target
  if a compact consumer is to meet the 44px target floor without enlarging the
  colour itself. The host still has to reserve a non-overlapping pitch; choose
  that geometry in a live layout before changing the type.
- A compact CPU/memory readout may replace a consumer's eight-dot handle.
  Compose it from `Stat`, `Meter` and `Prose` first; add no surface-named type,
  and only add a new neutral concept if the live design proves those primitives
  cannot express it.

### `ShellBorder` — decided 2026-09-06, 11a/11b/11c ALL LANDED

The owner has ruled. The decision record is in the consumer repo at
`qsm-desktop/docs/design-2026-09-06-shell-border.md` and the sub-phases in its
`spec/13-implementation.md` phase 11. In short:

- This library owns `Rollout`, both registries, the uniform packing, and the
  `.frag` plus its committed `.qsb`. It therefore gains a `qsb` build step and
  stops being pure QML. That cost is accepted, because the alternative — the
  consumer keeping the shader — means a second consumer writes its own and the
  two drift by construction.
- It never names Wayland, monitors or input masks. It publishes plain
  rectangles; the consumer turns them into a `Region`.
- `Rollout` finds its host by DUCK TYPING: seven functions plus one
  `fullscreen` read. Write that contract as a test BEFORE the move — it is the
  only thing keeping the rollout honest once the host is untyped.

Order, deliberately slow: port the shader unchanged, then ONE `ShellBorder`
with one dynamically anchored rollout, then an owner live review before
nesting, welding, resizing or fullscreen rules.

**All three sub-phases are done (11a 2026-09-06, 11b and 11c 2026-09-07).**
The consumer no longer has a `Rollout` or a shader of its own: `EdgeScene.qml`
went 1321 -> 999 lines and hosts a `ShellBorder`. It is 1166 again as of the
same day, because the popout keep-open region was written INTO it a few hours
later -- which is precisely why the next item says that geometry belongs here. Proof it was a MOVE and not a
rewrite, measured rather than asserted: the ported `Rollout.qml` is
byte-identical to the consumer's old file after substituting `host` back to
`scene` and `Style` back to `Theme`, and the panel rollout's live
`sceneBulgeDump` is identical before and after
(`rect:[357,0,886,563] radius:[0,0,28,28] blend:0.4 outness:1 edgeBits:4`).

`ShellBorder` gained ONE thing the port did not have: `entryFilter`, a
consumer-supplied `(id) => bool` applied to `bulgeEntries`, `maskRects` and
`fullscreenCapsuleEntries` alike. It exists because `Rollout.suppressed` does
NOT cover the consumer's fullscreen/focus-mode allowlist -- its `BarPopouts`
talks to the registry directly rather than through a `Rollout`, and its retract
`Behavior` has no suppressed guard, so a shrinking popout stays registered for
a full transition after the mode flips. Which surfaces survive a mode is policy
and stays with the consumer; the filter is how it says so.

**11a's own note (2026-09-06).** `qml/QsmShell/shaders/edgemelt.frag` and its
`.qsb` moved here byte-for-byte, `scripts/build-shaders` came with them, and
`docs/12-mechanism.md` is the normative reference code the shader implements.
A rebuild after the move produced an identical `.qsb`, which is the proof the
move changed nothing. Next is 11b, and its FIRST act is the seven-call host
contract as a test -- written before `Rollout` moves, not after.

One rule to carry on day one: `contentCenterOffsetX/Y`. A rollout is the band
BULGING, so content that centres itself centres in body plus band; centring in
the body alone is half a band-depth off, every time, on every rollout.

### Types with no consumer

Each was built against a hand-rolled equivalent in qsm-desktop and none has
been used yet. The migration IS the proof, and it is not a formality: every
type migrated this session turned out to be missing a rule, and two of them
(`ColorSwatch` clipping its own hover growth; its selection ring vanishing into
an accent-coloured sample) were invisible until a real consumer used them.

- `Dialog`, `Scrim`, `Skeleton` — and the desktop cannot supply consumers for
  the first two: it has no focus trap anywhere, and its session backdrop must
  be its own Wayland layer for compositor blur. Wait for a consumer that needs
  them rather than forcing one.
- `Popover` is PLACEMENT, not a tooltip and not a menu. Building either over it
  is real work — focus entry and return, keyboard activation, whether the
  content is reachable — and should wait for a surface that needs one.

### The type scale has a missing step — SETTLED 2026-09-07

`Prose` gained a tenth role, `supporting`: metadata's shape (muted, regular,
single line, elided) one step up the scale at `textSm`. `body` + `muted` is not
the same thing and was the tempting wrong answer -- it wraps and does not
elide, so it is the role for a paragraph, not for the line under a title.

The `prose-ladder` scenario captures title / body / supporting / metadata
together, because the only question worth asking about a supporting role is
whether it is tellable from its neighbours.

### Notification popup stack — LANDED 2026-09-07

All three of the trio are here now: `NotificationCard`, `NotificationCenter`,
`NotificationStack`. The stack was waiting on `Motion.revealSmall` and
`revealCurve` becoming library tokens, which they did with the rollout tier.

It takes `stack` (a plain pre-capped array) and `isAlive` as a QUERY FUNCTION
rather than a snapshot array -- a snapshot can read stale against the same
source's other bindings and made every dismissal look like an eviction. It
emits `dismissRequested`, `hoverChanged` and `geometryChanged`, and exposes
`cardGeometry()` so a consumer can drive per-row work (the desktop registers
fullscreen capsules) without this type ever holding a screen reference.

One defect this move CAUSED and its fix, because the shape recurs: the library
keeps a dismissed row on screen for its eviction slide, which is right. The
consumer then registered a capsule for every row `cardGeometry()` returned, so
a row already gone from the service kept a hole in the input mask until its
slide finished. Rendered is not alive. The consumer now filters on liveness;
the library was not wrong, but a consumer reading `cardGeometry()` must decide
which of those rows still MEANS anything.

### The popout keep-open geometry: half moved, half not -- 2026-09-08

Supersedes the 2026-09-07 entry that stood here, which is wrong twice over now.
It quoted the consumer's law that a rollout is kept open by where the pointer
is and NEVER by time; the owner overturned that on 2026-09-08. And it described
the geometry as still living entirely in the consumer, which it no longer does.

What the law is now: a rollout is open while the pointer is inside a hitbox
larger than the item, covering the corridors a hand sweeps through, plus a
delay after the pointer leaves. The region still does the work of telling
travelling from leaving; the delay only covers the last few pixels and the
frame boundary, which is why it is 180ms and not the old 180ms grace's job.

What moved here: `ScenePointer`, and `Rollout`'s `triggerAreas`, `hoverAreas`,
`closeDelay` and its `triggered` / `hovered` / `keepOpen` / `wantsOpen`
reports. `ShellBorder` takes the `pointer` so every rollout under a host reads
one. The rollout never opens or closes itself; the surface decides. The
consumer's OSD is on it.

What did not move, and why: the consumer's rail popout is `BarPopouts`, which
is itself a HOST (`childHost`, `parentHost`, a seam derived from its parent's
settled edge). `Rollout` cannot yet be the parent of a nested rollout, so
`BarPopouts` cannot become one at all. Until it can, the rail keeps its own
union predicate, fed by the shared `ScenePointer` and using the same 180ms
token. The logic is in two places; the number is in one.

Still unsettled, carried over unchanged: the travel triangle is a geometric
NO-OP today, because the popout is flush with the band and the band already
spans the full height. Either it is genuinely redundant, or flushness fails in
some state and the triangle is load-bearing there. Nobody has checked which,
and a test is exactly how to find out.

### Carried notes from the migration -- 2026-09-08

Small things nobody has to act on today, written down so the next session does
not rediscover them.

**`previews/Preview.qml:158` warns on unqualified `modelData`.** The
`prose-ladder` `Repeater` reads it from a parent element. It predates the unit
split and lives in the shrinking half of the hybrid host, so it dies with the
inline children rather than needing a fix of its own. `previews/units/` is
clean: `qmllint` reports zero warnings there.

**`tests/units/tst_units.qml` reads `previews/scenarios.json` over
XMLHttpRequest**, which Qt refuses for a local file unless
`QML_XHR_ALLOW_FILE_READ=1` is set. `scripts/run-unit.mjs` and
`scripts/validate-library` both set it, and the test says which script to go
through when the body comes back empty, because Qt answers a forbidden read
with an empty body rather than an error. A direct `qmltestrunner` call without
the variable fails on that check, not on a parse error.

**The migration is a defect detector, not tidying, and should be scheduled as
one.** Five types have been through the full loop and turned up real defects
the moment something drove them: `Slider` had no keyboard route and no focus
state at all and reported hover while disabled; `ListRow` truncated its own
content when sized naturally; `StateLayer` still reported hover when
`interactive: false`; `Switch` had keyboard handlers without a Tab route, so
keyboard activation was unreachable; `TextField` had the same dead Tab route
-- the inner `TextInput` had no tab stop, so only a pointer click or a
programmatic `focusField()` could reach it, hid its failed border under the
generic focus ring and showed an I-beam over its slot actions. None was visible
to reading the source, to `qmllint`, or to an offscreen capture. Expect the
remaining types to pay the same way, and budget for fixing what they surface
rather than only for writing the unit and the test.

**~36 types still to move.** `tests/interaction/tst_library.qml` is the meter:
it stood at 66 assertions before the drain and 64 after `ListRow` left. It dies
empty.

### `ListRow` breaks two laws it is supposed to carry -- 2026-09-08

Both found by writing `tests/units/tst_ListRow.qml`, both verified in the
source, neither fixed: the first changes how the consumer's desktop looks right
now and that is the owner's judgement, and the second is a layout change that
wants its own look.

**A report-only row is dimmed exactly like a disabled one.**

    selectable: _normal && !disabled && interactive
    proseColor: !selectable ? Style.textMuted : danger ? Style.danger : Style.text

`interactive: false` is how a row says "I am a reading, not a target", and it
lands in the same bucket as `disabled`. The law this type exists to carry says
the opposite in as many words: unavailable dims, not-a-target does not, because
dimming a reading also says the reading is stale. The consumer's device rows
are exactly this shape, so every live value in them is drawn as though it were
old. The test file pins the BEHAVIOUR (a report-only row refuses the routes
without claiming `disabled`); the colour is not asserted, because appearance is
judged in the live window.

**An empty trailing slot takes space.**

`trailingSlot` is a `RowLayout` with `spacing: Style.space2` and no gate on
whether it has children, unlike `leadingBox` which checks. Measured with a
throwaway probe: a bare row already carries the gap, and adding trailing
content of implicit width 24 grew the row from 41 to 65, exactly 24 rather than
24 plus the spacing, which is the proof the gap was paid while the slot was
empty. The component's own comment and the AGENTS.md law both say an empty slot
takes no space.

Also not tested and not fixed: the supporting line hides itself when it repeats
the primary, and reaching that `Prose` from a test would mean indexing into
`children`, which couples a test to the component's internal shape.

### Three findings the owner has seen and left standing -- 2026-09-08

Each ended in a decision, not a fix, so each needs its reason on the record.

**The `volume` glyph is not centred in its own box, and its muted sibling is.**
lucide's `volume-2` draws ink from x 2 to about 20.4 in a 24 box, so it sits
left of the box centre and reads left of whatever it is centred under. Measured
from the live objects, the layout is exact: `ListRow`-style slot centring puts
`IconButton` on the track to the pixel, `delta = 0`. `volume-muted` is a
different glyph (`volume-x`), symmetric, needing nothing. So the pair shifts
sideways by about 0.68px whenever a channel mutes.

The owner compared five offsets in a live window and judged +1px too far right,
then chose to leave it at 0 rather than take a smaller value. Left deliberately.
The one value with a non-taste argument behind it is +0.82 units, which is what
makes `volume` and `volume-muted` land in the same place and stops the mute
jump; it was offered and declined for now.

**The preview control strip marks the last option CLICKED, not the state the
unit is actually in.** Open a unit whose `variant` already sets a state and no
button shows as active, which reads as "nothing is applied" when something is.
Deriving it is only possible for `set` options: a `call` option invokes a method
and leaves no property to compare against, so there is no uniform answer for
both kinds. Left because the strip is harness chrome and the honest fix is a
design decision about what `active` should mean on an action button.

**`Popover.qml`'s comment says a trigger is "held long enough".** That is the
same word the owner rejected on `Rollout`, where `held` read as holding a mouse
BUTTON down and became `hovered` plus `keepOpen`. `Popover`'s own delay is a
different mechanism and renaming it would change unrelated semantics, so it was
left. Worth one look the next time that file is open.

### `StateLayer` was the only public type with no test — CLOSED 2026-09-08

107 lines, and every type in `Components/` is now exercised
somewhere under `tests/`. It is also, with some irony, the type that every
`clip-growth` finding in the consumer's `ui-guard` is ABOUT -- three separate
gate failures in one session, all naming a component nothing here tests.

## Later

- Decide whether the divider needs vertical orientation after a real layout
  requires it.
- Add SVG aliases and validation only when the first naming conflict appears.
- Add a light theme only after its palette is designed and reviewed.

## Known Environment

- OpenCode retired the `gpt-5.4-mini` runner models while the generated
  `qsm-runner` manifest still named `openai/gpt-5.4-mini-fast`. The provider
  accepted the catalog name but rejected execution for the ChatGPT/Codex
  account, and Task surfaced only an empty result. A runtime override to
  `openai/gpt-5.6-luna-fast` completed runner contracts and all verification
  normally. The durable manifest correction belongs in qsm-marketplace, not
  this library.

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

- **`clip: true` shaves a child's hover growth.** A control that answers a
  pointer by growing cannot sit inside a clipping ancestor sized to it — the
  response is cut back to nothing and the control reads as dead. `ColorSwatch`
  clipped itself this way to round its sample; the sample carries its own
  corner now. Measured by the consumer's `ui-guard` at 1.3px off a 32px swatch.
- **A `Rectangle` radius does not round its children, and `clip` does not
  either.** Item clipping is RECTANGULAR. `Rectangle { radius; clip: true }`
  around an `Image` leaves the picture square inside a round frame, and
  `layer.enabled` on the child does not help. `MultiEffect.maskSource` is the
  only mechanism that cuts the corners. Three surfaces in the consumer had this
  bug and none of it was visible in the code.
- **`Keys.onSpacePressed` needs focus, and nothing gives it by default.** A
  component that declares key handlers without `activeFocusOnTab` and without
  moving focus on pointer press has advertised a keyboard path that cannot be
  reached. By the five-states law that is a state it does not have.

- **`Keys.onPressed` accepting an event does NOT stop the per-key handler.**
  `Keys.onPressed` and `Keys.onDownPressed` hang off the same attached object,
  and setting `event.accepted` in the generic one does not suppress the
  specific one. A field carrying both moved a launcher list two rows per
  keystroke. Use ONE dispatcher.
  `tests/units/tst_TextField.qml` keeps that bug.
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
