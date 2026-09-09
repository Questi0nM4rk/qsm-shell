# qsm-shell

- Build production QML before tests, documents, fixtures, or abstractions.
- A feature is complete only when real QML runs and its visible or interactive
  result has been checked.
- Do not add JavaScript models of QML behavior, expected-red tests,
  source-shape tests, documentation gates, new manifests, or assertions about
  pixel positions or appearance. How a thing looks is a human's job against
  the live window, never an assertion.
- Add one focused regression check only after a real behavior works.
- `tests/units/tst_<Type>.qml` is one behaviour test per type, driven by real
  pointer and key events, runnable alone. `tests/interaction/tst_library.qml`
  is being drained into these one type at a time and dies empty at the end of
  the migration. `tests/units/tst_units.qml` is the one test that is not
  per-type: it constructs every unit named in `previews/scenarios.json` and
  walks every option every declared `controls` group names, so a control
  naming a property the type does not have fails immediately.
- Keep `qsm-desktop` policy, services, persistence, and compositor integration
  out of this library.
- For every component design, interaction, or visual change, load `ui-design`
  before writing, use `ux-audit` to verify interaction, and use `ui-audit` to
  verify the native visual result. On this workstation,
  `~/Downloads/design-system-blueprint.pdf` is an additional design source:
  semantic tokens, the 4px spacing rhythm, explicit component states,
  consistent type/icon scales, and purposeful motion. Project laws and measured
  native QML still outrank generic guidance.
- Native QML is the only place a component is looked at. A component lives
  once, under `qml/QsmShell/Components/`; `previews/units/<Type>.qml` is its
  one proof harness, and `npm run preview` opens it in a real wayland window
  for a person to judge. `npm run capture` still writes an offscreen PNG, but
  a capture proves a scene rendered, never that it looks right. There is
  deliberately no second rendering of any component in another language,
  because a mirror that shows the right colours and the wrong shape is worse
  than no mirror.
- Design every meaningful resting, hover, pressed, focused, selected, disabled,
  loading, empty, and error state that the component actually supports.
- Pointer and keyboard routes must perform the same action, keep focus visible,
  and provide immediate feedback. Motion communicates state and respects
  `Style.reducedMotion`.
- Every meaningful user action has one semantic entry point. Pointer and
  keyboard routes call it, and consumers can call it directly; never implement
  programmatic control by synthesizing pointer/key events. A controlled
  component still reports intent and never mutates state owned by its host.
- Review native captures for hierarchy, spacing, contrast, typography, and
  target clarity before calling a visual change complete.
- Use `tokens/deep-night.json` for shared values and regenerate outputs with
  `npm run tokens`.
- Comments explain non-obvious mechanics only. Git history, task history, and
  restatements of code do not belong in source comments.
- Keep durable documentation to `README.md` and `docs/BACKLOG.md` unless a
  genuinely irreversible architectural decision needs a short record. `docs/adr/`
  holds the irreversible decisions (ADR 0001: controls on QtQuick.Templates) and
  `docs/components/<Type>.md` holds one short design record per type, the
  `expected` column an audit measures against.
- `docs/12-mechanism.md` is NORMATIVE code for the edge shader: use its exact
  formulas, and changing behaviour means editing that file first. It moved here
  with the shader; the consumer repo keeps only a pointer.
- The shader is the one non-QML thing here. `.frag` and `.qsb` are committed
  together -- rebuild with `bash scripts/build-shaders` and `npm test` fails on
  drift, because the runtime reads only the `.qsb`.
- Do not claim completion from mocks, lint, screenshots of different surfaces,
  or tests that expect production to fail.
- Run `npm test` before handing work back.

## Preview workflow

- `previews/units/<Type>.qml`, one file per TYPE in
  `qml/QsmShell/Components/`, PascalCase, mapped 1:1. A unit takes one
  property from the host, `variant`, owns its own implicit size, reads
  `Style` and never `Tokens`, and never installs `Style.backend`.
- Several scenario KEYS can map to one unit. `previews/scenarios.json` keys
  are the capture API and they keep their names: `level` and `osd-slider`
  are both the `Slider` unit, `list-row`, `device-row` and `result-row` are
  all the `ListRow` unit. A unit file is never named after a surface.
- `previews/Preview.qml` is a hybrid host: a `Loader` for names already
  moved to `previews/units/`, today's inline children for the rest. The
  hybrid lasts the whole migration and is what lets each type be proved
  separately. 9 of ~45 types are moved so far: `Badge`, `Spinner`,
  `ProgressBar`, `Divider`, `Slider`, `ListRow`, `StateLayer`, `Switch`,
  `TextField`.
- A unit may declare `controls`: groups of buttons the live host renders
  above the scene, so property-only states (`disabled`, `selected`,
  `indeterminate`) are reachable by clicking. Shape:
  `[{ label, options: [{ label, set: {prop: value} } | { label, call: "method" }] }]`.
  States a pointer can already reach (hover, press, focus) must never be
  faked as control options.
- Commands: `npm run preview -- <key>` opens the real scene in a real
  wayland window; `npm run capture -- <key>` still writes the offscreen
  PNG; `npm run unit -- <Type>` runs one test file, `--window` runs the
  same file on the compositor; `bash scripts/capture-all <dir>` captures
  every scenario. `--inspect <file>` on `preview` and `capture` writes the
  latest item-tree dump (same shape as the consumer's `qsm inspect`); F12
  re-dumps in the live window.
- When an agent opens a preview, it announces that it is taking the pointer,
  drives the whole planned state trace, then says the window is ready and
  stops injecting input so the owner can judge it. If the owner says they are
  away from the machine, the agent completes that judgement loop fully
  automatically instead of waiting for a handoff that cannot happen.
- Capturing the same STATIC scenario three times gives three different
  sha256 sums (GPU rasterisation noise, roughly 0.01% of a scenario's
  ~400,000 pixels differ), and an animated one lands on a different
  animation phase every run (`spinner`: 74 differing pixels between two
  runs; `qml --fixed-animations` does not help, the rotation runs on the
  render thread). Pixel-diffing captures is struck out as overtesting.
  `capture-all` proves no scenario stopped rendering; it never compares
  pixels.
- **The offscreen capture does not rasterise `SvgIcon` glyphs.** A blank
  where an icon belongs is the pipeline, not the component. Verified by
  opening the same scene in a live window, where the glyph paints. So a
  capture proves layout and that a scene renders at all; anything with a
  glyph in it can only be judged in the live window.
- **A `WheelHandler` never sees a wheel event in a live Wayland window.**
  Measured with a REAL wheel on this Qt6 Wayland QPA: a notch over a
  `WheelHandler` logs nothing, while a `MouseArea.onWheel` sitting beside it
  in the same scene reports `angleDelta (0, -120)`. Offscreen both work, so
  a wheel route built on a handler passes every test it has and is dead
  under a hand. This was recorded here for a day as "synthetic `mouseWheel`
  does not reach a `WheelHandler` under `--window`", which read as a test
  harness limitation and hid a live defect. Take the wheel with a
  `MouseArea { acceptedButtons: Qt.NoButton }`; pointer, key and focus
  events work under both platforms.

## Migrating a type

Take one type from `previews/Preview.qml`'s inline children to
`previews/units/<Type>.qml`, in order:

1. Pick a TYPE, never a surface. Check `previews/scenarios.json` for keys
   that are the same type under different names; they fold into one unit
   and the keys stay.
2. Write `previews/units/<Type>.qml`. It takes `variant`, owns its implicit
   size, exercises the type's SLOTS rather than flattening them into
   properties, and answers any signal the type hands upward, or the
   control is dead in the window.
3. Declare `controls` for the states a pointer cannot reach. Never fake
   hover, press or focus as options.
4. Delete the type's inline children from `previews/Preview.qml` and point
   its scenario keys at the unit.
5. Write `tests/units/tst_<Type>.qml` with real pointer and key events,
   asserting behaviour and never pixels, and drain that type's lines out of
   `tests/interaction/tst_library.qml`.
6. Prove the tests have teeth: break the component so the most valuable
   assertion fails, watch it fail with a message that names what broke,
   revert.
7. Run `npm run unit -- <Type>` offscreen and with `--window`, then
   `npm test`.
8. Open `npm run preview -- <key>`, drive it by hand, and let the owner
   judge the look and the feel. That judgement is not delegable and no
   capture substitutes for it.

Two rules that belong with the loop, because both were broken while it ran:

- A defect the migration uncovers belongs in the COMPONENT, not worked
  around in the unit. A unit that compensates for a component's bug hides
  it from the next caller, who gets the same failure with no clue why.
- Verifying anything in the live window needs the pointer to actually be
  where you think it is. `ydotool mousemove --absolute` is accepted and
  silently does nothing on this machine, and this Hyprland's
  `hyprctl dispatch` takes a lua call, so `movecursor X Y` is a parse
  error. Drive the cursor with damped relative `ydotool mousemove` steps
  and confirm with `hyprctl cursorpos` before believing any reading;
  trusting `--absolute` once produced a confident and completely wrong
  conclusion about live behaviour. `qml` has no hot reload either: a
  preview window must be restarted to pick up an edit, unlike the
  consumer's quickshell.

## Component laws

Earned, each from a specific failure. Break one and name which.

- **A type is a concept, never a surface.** `OsdSlider` and `LevelBar` were one
  slider wearing two names because two surfaces asked for it; they differed in
  three numbers. If a name contains where it is used, it is wrong. A library
  that grows a type per call site stops being a library.
- **No numbers in a component.** Every measurement comes from `Style`. Where a
  scale had a gap, components filled it by typing a literal, and 16, 18 and 22
  all became "the small icon" in three files. A call site that needs a different
  value passes it as a property; the library keeps one default.
- **Never read `Tokens` from a component.** Read `Style`. A value taken from
  `Tokens` is a value the consumer cannot retheme, which is two sources of
  truth wearing one name.
- **Every interactive component defines all five states**: rest, hover, press,
  focus, disabled. `StateLayer` owns them and the component FORWARDS them —
  owning a state the component cannot express is the same as not having it.
  Focus was missing for a keyboard-first shell, which meant a person driving by
  keyboard had nothing telling them where they were.
- **Content goes in slots, not properties.** What sits above, below or inside a
  control is the consumer's business. A slider that hardcodes an icon under its
  track is a slider that has to be rewritten for the second surface. An empty
  slot takes no space.
- **A component never manages its own dismissal.** It reports `hovered`; the
  surface holding it decides what that means. Otherwise the component has to be
  told about every surface it might ever sit in.
- **One fact, one place.** A rule components need but cannot see — who is
  driving, whether a hover may claim a selection — lives in one singleton the
  consumer sets. Three surfaces each repeating the same guard means the fourth
  will forget it.
- **Prefer a function over a rule people must remember.** `Style.childRadius`
  exists because "inner radius = outer minus inset" is arithmetic every call
  site would otherwise redo and keep in sync with a padding it does not own.
- **`lineHeight` belongs to wrapping text only.** On a single line it grows the
  line box and the glyphs stop sitting in the middle of it.
- **Centre row content by filling the row, not by baseline.** `RowLayout`
  baseline-aligns text and an icon has no baseline to share, which put a button
  label half a pixel below its own pill. Half a pixel reads as "not centred".
- **A number that moves the wrong way is worse than no number.** Anything
  derived from an instantaneous reading gets averaged before it is shown.
- **Lint proves a file parses; only running it proves it works.** `qmllint`
  cannot see a binding that fails to resolve or one that feeds itself. Twenty
  new types shipped linted-and-never-run and two of them were broken: a
  `Flickable`'s declared children become children of its `contentItem`, so a
  scroll indicator was both chrome and content and its height fed the content
  height fed its own height. `tests/interaction/` instantiates every public
  type for exactly this.
- **A type whose name says where it is used is a type you have twice.**
  `MenuRowItem`, `PopoutRow` and `ResultRow` were one row wearing three names,
  differing in a handful of numbers and in which of the three had remembered
  which rule. Same for `SearchField`: a search box is a text box with a glyph
  in its leading slot.
- **Unavailable and not-a-target are different states.** `disabled` means the
  action exists and cannot be taken now, so it dims. A row that only REPORTS
  is showing the truth at full strength and simply is not clickable. Dimming
  it to say "you cannot click this" also says "this reading is stale".
- **A configuration flag per key the consumer might want is the wrong shape.**
  Four `intercept*` booleans covered four keys and not the fifth. One hook
  carrying the live event covers every key, and the surface that knows what
  the key means is the one that decides.
- **A copy with the reasoning stripped out is worse than no copy.** It is the
  one that looks canonical and cannot say what it is for. Found three
  implementations of one fuzzy scorer; the library held the one with its
  explanation deleted.
- **Reduced motion shortens a DURATION and lengthens a PERIOD.** A one-shot
  transition calms by getting shorter; a loop calms by getting slower.
  Shortening a spinner's period makes it whirr.
- **A hover reader belongs on the ANCESTOR of the surfaces, never stacked
  with them.** Measured with real pointer events: a `HoverHandler` on a
  sibling item BELOW the surfaces never sees the pointer; on a sibling
  ABOVE it sees the pointer and steals hover from everything underneath;
  declared on the ancestor both work. `blocking: false` changes neither
  sibling case. The claim that "every hover handler under the point is
  notified" is true only for several handlers on the SAME item, and a
  consumer's keep-open test was dead for a day because it was written on
  the other reading. `ScenePointer` exists so this is a type with the rule
  in it, not a rule people must remember.
- **A component that hands its state upward is dead in a preview that does
  not host it.** `Slider` emits `moved` and never writes its own `value`,
  because the host owns it. The unit did not answer `moved`, so in the
  live window the slider ignored the pointer, the wheel and every arrow
  key, and the owner reported it as a broken control. Every unit for a
  type that hands state up must play the host.
- **The width a component asks for must include the inset it then gives
  away.** `ListRow.implicitWidth` reported its body's span while the body
  loses two insets to its own margins, so a row sized by its own implicit
  width ate two insets of its content. Invisible for as long as every call
  site imposed a width; the first caller to trust natural sizing had its
  text truncated.
- **One keep-open rule for every rollout, not one per surface.** A rollout
  is open while the pointer is inside its hitbox, which is larger than the
  item and covers the corridors a hand sweeps through, plus a delay after
  the pointer leaves. `Rollout` reports `triggered`, `hovered`, `keepOpen`
  and `wantsOpen` and never closes itself; the surface decides. Two
  surfaces each invented their own version of this and both were broken.
- **A name that lies is worse than a long name.** `held` read as holding a
  mouse button. `hovered` is the pointer being in the hitbox right now, and
  `keepOpen` is that plus the delay, because a `hovered` that stayed true
  after the pointer left would be a name that cannot be trusted.
- **One type may have several purposes; its unit changes the whole
  composition.** Plain text, search, password and number are one `TextField`,
  not four field types. A purpose switch changes input semantics, leading
  glyph, trailing action and sample value together. Changing only
  `inputType` left a magnifier on a password field, which was a state no real
  host would build. Separate scenario keys may all map to the one type unit.
- **A generic focus ring never erases a stronger semantic state.**
  `StateLayer`'s accent ring sat above `TextField`'s danger border, so a failed
  field stopped looking failed exactly while a person focused it to repair
  the value. The host passes the semantic colour through `focusColor`; error
  remains error while focused.
- **The cursor describes the region under it, not the outer component.** A
  full-field I-beam covered the hand cursor of clear, reveal and submit
  actions in the field's slots. The editable body stays I-beam, a trailing
  action is a hand, and a leading action states its cursor explicitly. A
  clickable glyph that still shows a text cursor is an affordance that denies
  its own action.
- **Reveal changes visibility, never input semantics.** A password reveal
  keeps `inputType: "password"` and its sensitive-data/input-method hints; it
  changes only `passwordVisible`. Turning a password into a text field to show
  its characters silently drops the protections that made it a password.
- **Invalid input is a fact; failed is a host verdict with copy.**
  `acceptableInput` reports the validator, while `failed` is set by the host
  that can explain what failed in `Field`. Intermediate number text must not
  paint an unexplained error automatically. Return and a clickable submit
  glyph both call `accept()`; keyboard-only facts such as `selectionClaimed`
  stay on the keyboard route and are not invented by programmatic calls.
- **A text root paints under its own padding.** `T.TextField` scrolls long
  text left under `leftPadding`, which is where a leading slot sits. A text
  control with slots is a `T.Control` with a clipped `TextInput` content
  item, the shape `T.SpinBox` uses; the template still owns padding and
  states.
- **Disabled dims by colour, never by opacity on a composite.** Opacity on a
  control applies to each child separately, so a translucent thumb shows the
  translucent fill through it and three layers stop being three things.
  `Style.disabled(colour)` blends each colour toward the background opaquely
  and the layers stay layers.
