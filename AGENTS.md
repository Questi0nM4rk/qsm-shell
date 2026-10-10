# qsm-shell

Reusable QML components for Qt 6 and Quickshell desktops. One developer and
one current proof consumer (`qsm-desktop`); the API must remain usable by other
desktops without inheriting that consumer's policy. Everything is judged by one
question: does the feature work in a live window, and does every pixel of it
follow the design sources.

## Direction

- The product is a fully functional, beautiful component system with dynamic,
  accessible UX. Workbench is its supporting tool, not the delivery priority;
  improve harness UI only when it blocks component development or judgement.
- qsm-shell is Quiet Luminous: a calm dark shell that stays subordinate to the
  application beneath it while its information remains immediately legible.
  The default deep-night theme uses quiet raised surfaces, luminous text and a
  restrained lilac accent; it is rethemeable through `Style`. Aim for cosy,
  minimal dusk/night: deep quiet grounds and diffuse lilac light, inspired by
  the desktop's `dark-rain-world.png` and `light-forest-dark-winter.jpg` wallpapers.
  Borrow their atmosphere, not their artwork or decorative noise.
- Build auxiliary and transient shell primitives, not a web dashboard: bar and
  rail status, panel popouts, launcher, OSD, notifications, session actions,
  colour tools and compact performance readouts. The bar is glanceable; a
  popup or modal is obvious and needs no learned route.
- Visual hierarchy comes from whitespace, the semantic type scale and the
  surface ladder before boxes or colour. The accent belongs to focus,
  selection and primary action, never passive metrics. One 4px rhythm, one
  type scale, one icon scale and purposeful motion make the parts one system.
- Do not build marketing cards, generic web widgets or permanent dashboard
  chrome. A component serves one shell task, remains compact, and reports
  intent while the owning surface decides policy and consequences.
- Ship a fully working, feature-full MVP. Features first, as fast as
  possible. Fewer docs, more features.
- The least code that works. The least documentation that keeps the next
  session honest. A line of either needs a reason.
- The owner tests and judges ONE item at a time. Prepare it, explain its task
  and reachable states, ask the owner to check it, then wait. Revise that same
  item from feedback until the owner accepts it before moving on. An agent's
  capture, tree dump, audit or green suite is not acceptance.
- No automatic tests, validation, capture sweeps, input traces or skill evals.
  Run or add checks only when explicitly requested; a request to build or
  review a component is not permission to test it. No TDD, coverage growth,
  JavaScript models of QML behaviour, source-shape tests, documentation gates,
  or standalone assertions about static text, sizes, colours or pixels. If
  requested, check real input and changing states along an integration flow.
- Before touching a component, answer in writing (the component record):
  what does a fully working, production-ready X look like? Which settings
  does it have, how does it behave under pointer, keyboard, wheel, focus and
  a screen reader, which sizes exist, what grows and what stays constant, and
  which of that is globally accepted across component libraries rather than
  our taste. Start with the person's shell task and consequence, then choose
  the interaction, hierarchy, content, glyphs and motion. Compare caelestia
  (`~/Clonned/caelestia/repo/components/controls/Styled*.qml`) and from other
  component libraries (Material 3, Radix, shadcn, Fluent) before inventing;
  use relevant patterns, not the union of every library's configuration flags.
- A component is a caller. It renders state the host owns, exposes every
  action as a function listed in `actions`, and reports intent (`moved`,
  `committed`, `accepted`, `hovered`). It never mutates host state and never
  manages its own dismissal. Pointer, keyboard and programmatic routes call
  the same function; programmatic control is never a synthesized event.
- Every pixel is a decision with a token behind it. Design sources, in rank:
  the owner's accepted design and current component record, the component laws
  below, `design-system-blueprint.pdf`
  at the repo root (semantic tokens, the 4px rhythm, every state designed,
  one type and icon scale, purposeful motion), then the qsm-uiux skills:
  `ui-design` informs preparation; `ux-audit` and `ui-audit` run only when
  the owner requests an audit. Design every resting, hover, pressed,
  focused, selected, disabled, loading, empty and error state the component
  supports. Motion communicates state and respects `Style.reducedMotion`.
  Native measurements describe what is rendered, not what the owner has accepted.
- No versioning in docs: no dates, no CLOSED/LANDED history, no counters. A
  doc says what is true now or it goes. Durable docs are `README.md`,
  `docs/BACKLOG.md` (open items only), `docs/components/<Type>.md` (one short
   record per type, `expected` describes the owner-review contract) and
  `docs/adr/` for irreversible decisions. `docs/12-mechanism.md` is NORMATIVE
  code for the edge shader: use its exact formulas, and changing behaviour
  means editing that file first.
- Comments explain non-obvious mechanics only. History and restatements of
  code do not belong in source.
- `qsm-desktop` policy, services, persistence and compositor integration stay
  out of this library.
- Load the project skill `develop-component` for the step loop of one type.
- Give researchers and implementers small, bounded tasks; keep user judgement
  with the owner. Use `openai/gpt-6-luna`, medium for straightforward work and
  runners, high for complex research or mechanics. A runner gets a testing
  task only after the owner requests that check.

## Definition of done for a component

1. Stands on its `QtQuick.Templates` type where one exists (ADR 0001).
2. Five states through `StateLayer`, plus its own (readOnly, failed,
   indeterminate) where they exist.
3. Every action is a function listed in `actions`; pointer, keyboard and
   callers share it.
4. Reports every fact a host would otherwise have to derive: hover, keep-open,
   dismissal intent. A host that has to re-compute one of these to work
   around what the component does not report is a signal the component is
   unfinished, not that the host is clever.
5. Natural size is a constant. Long content scrolls or elides, never grows
   the control.
6. Every number comes from `Style` or `Motion`.
7. `workbench/units/<Type>.qml` hosts every intent and exposes coherent examples
   and supported property states for the owner to inspect.
8. The owner judges its look and feel in the live window and accepts the item.
   Feedback is fixed in the owning component or token; unresolved decisions
   remain one line in `docs/BACKLOG.md`. Requested automated checks are separate
   evidence, never a replacement for acceptance.

## Interaction contract laws

- **Typed required/optional fields**: Schema before rendering, not blind
  `String(value)` fallback. Provider sent `origin/name/payload` but Workbench
  rendered missing `sequence`/`kind`/etc as `undefined`. Normalize display once
  at ingress, typed required/optional fields, preserve original
  `identity/provenance/node` metadata, omit missing optionals not
  `String('undefined')` or made-up success. — `../qsm-workbench/docs/interaction-contract.md#event-boundary`
- **Kind vs identity**: `kind` denotes distinct semantic component, not shared
  visual template. Instance/node identity is separate (app rows share `app`
  type). Title does not fix missing identity. — `../qsm-workbench/docs/interaction-contract.md#identity-and-provenance`
- **Reset suppresses initialization noise**: `reset` cancels timers/work, no
  later completion. Actual native cancellation must not activate controls.
- **Diagnostics are user-tools**: Events log is selectable, Ctrl+C works, Copy all
  copies entire log, empty state shown, long content scrolls, selection stable
  on append/cap. Actual `Events` uses `Flickable+TextArea.flickable` (NOT
  `ScrollView`). — `../qsm-workbench/docs/interaction-contract.md#layout-and-diagnostics`
- **One behavior vertically, sibling-pattern search**: When a defect is found,
  follow one behavior vertically and search sibling patterns before fixing.
  For rendering/motion, follow `develop-component`'s **Motion and rendering
  changes** through registry helpers and shader paint to removal/unloading, not
  only the animated component. Replace conflicting spec formulas in place.
  Do not invent raw key events from state changes, do not claim focus support
  merely because native driver accepts keys. No global every-pointer-move
  telemetry. Component intent vs service result vs scenario setup vs
  injected/route evidence are separate. Repeated same-value operations matter;
  observe operation signal not propertyChanged alone.
- **Review process**: Symptom patches (add title instead of kind) are insufficient.
  Incomplete route testing does not prove readiness. Prior suite predates edits
  and does not prove current behavior. Owner approval only for named item;
  runtime checks only when explicitly requested. Report source-reviewed vs
  runtime-exercised vs owner-accepted separately.
## Commands

- Preview and requested captures use installed `qsm-workbench` on `PATH`, never
  sibling checkout scripts. Session control uses `qsm-workbench session`; attach
  by explicit PID and confirm provider plus the required story through `describe`.
  `qsm-shell` and `qsm-desktop` are different catalogs; Notification Layer belongs
  to the desktop provider. Do not reuse an old session file blindly.

- `npm run preview` opens the storybook catalog in one real wayland window.
  Every story is reachable, the catalog is a browser, and a story window holds
  one exact item. `npm run capture -- <key>` writes the offscreen PNG.
  `npm run unit -- <Type>` runs one test file; `--window` runs it on the
  compositor.
  `bash scripts/capture-all <dir>` captures every scenario. `--inspect <file>`
  on `preview` writes the item-tree dump; F12 re-dumps live. Captures write PNGs;
  native glyph judgement and inspection belong to the live preview.
- `npm run tokens` regenerates outputs from `tokens/deep-night.json`.
- The shader is the one non-QML thing here. `.frag` and `.qsb` are committed
  together; rebuild with `bash scripts/build-shaders`, `npm test` fails on
  drift.
- These are available commands, not an automatic work loop. Run tests,
  validation or captures only on the owner's explicit request. State what is
  prepared, user-accepted and unverified accurately.
- For requested native recordings, capture actual frames at 25–60 fps according
  to motion complexity: roughly 25 fps is enough for simple content/fades; deep,
  difficult animation requires genuine 60 fps. A 60-fps CFR encode with
  duplicated frames does not prove 60-fps capture.

## Preview units

- A component lives once, under `qml/QsmShell/Components/`.
  `workbench/units/<Type>.qml` is its one proof harness, one file per TYPE,
  PascalCase, mapped 1:1, and `workbench/stories.json` names the scenario
  keys. A unit takes one property from the host, `variant`, owns its own
  implicit size, reads `Style` and never `Tokens`, never installs
  `Style.backend`, exercises the type's SLOTS, and plays the host: it answers
  every signal the type hands upward or the control is dead in the window.
- A unit is a FRONTEND for the event API the harness drives, and that is the
  whole of its contract with workbench: its `controls` declaration, its
  `integration` object (`events`, `actions`, `observables`, `runAction`,
  `keys`, `textDriver`, `checkpoints`) and the signals it reports upward.
  Every name in it is kebab-case and matched exactly. Everything else about the
  unit is its own business and the harness must not know it. A harness that
  needs a switch statement to find a unit has welded itself to the catalog,
  and the catalog then cannot grow.
- Several scenario KEYS map to one unit and keep their names (`level` and
  `osd-slider` are both `Slider`; `list-row`, `device-row`, `result-row` are
  all `ListRow`). A unit is never named after a surface.
- A unit may declare `controls`: groups of buttons the live host renders
  above the scene, so property-only states (`disabled`, `selected`,
  `indeterminate`) are reachable. Shape:
  `[{ label, options: [{ label, set: {prop: value} } | { label, call: "method" }] }]`.
  States a pointer can reach (hover, press, focus) are never control options.
  Names are DERIVED from this declaration, never written a second time.
- A fixture is a designed example of a real task, not random API values.
  Glyph, verb, reading, confirmation and outcome describe the SAME intent.
  Switch a purpose as a whole composition; decoration must earn its place.
  A sample glyph does not become library policy or a required visual slot.
- Controls expose supported cases rather than one arbitrarily chosen instance:
  per-option availability includes first, middle, last and all disabled; content
  includes empty and long where valid; sizes include the theme's supported names.
  Keep them compact and understandable; do not invent states the type lacks.
- **The storybook holds every story, there is no entry point that opens one,
  and units migrate one at a time with the catalog as the checklist.** A type
  moves to `workbench/units/` and its keys are repointed before the next type
  starts; half a catalog in two places is worse than both halves finished.
  `npm run preview` with no argument opens the catalog, a story window holds
  one exact item, and the catalog is a browser rather than a judging surface.
- Prepare only the current item for owner review. If asked to open or operate
  its preview, use `qsm-compuse` on workspace 10, announce pointer use, then
  stop input and say what the owner should inspect. Wait for feedback; owner
  absence never grants self-acceptance or an automatic catalog sweep. Close
  only your own test windows after the owner finishes; leave no stray instances.
- A defect the unit uncovers belongs in the COMPONENT, never worked around in
  the unit.
- `qml` has no hot reload: restart the preview window to pick up an edit.

## Measured platform facts

- A capture proves a scene rendered, never that it looks right. The same
  static scenario gives a different sha256 every run (GPU noise) and an
  animated one lands on a different phase. Pixel-diffing is struck out.
- **The offscreen capture does not rasterise `SvgIcon` glyphs.** A blank
  where an icon belongs is the pipeline. Anything with a glyph is judged in
  the live window only.
- **Under the Qt6 Wayland QPA a `WheelHandler` never sees a wheel event**,
  real or synthetic, while a `MouseArea.onWheel` beside it does; offscreen
  both work. Take the wheel with `MouseArea { acceptedButtons: Qt.NoButton }`,
  which CONSUMES the wheel unless it sets `accepted = false`, so a path that
  does nothing with an event must say so or it disables an enclosing
  scroller.
- `ydotool mousemove --absolute` is accepted and silently does nothing, and
  this Hyprland's `hyprctl dispatch movecursor` is a parse error. Drive the
  cursor with damped relative `ydotool mousemove` steps and confirm with
  `hyprctl cursorpos` before believing any reading.
- `/usr/bin/qmltestrunner` is Qt 5. The Qt 6 one is
  `/usr/lib/qt6/bin/qmltestrunner`, with real `mouseClick` / `keyClick` under
  `QT_QPA_PLATFORM=offscreen`. A test that reads a catalog over XMLHttpRequest
  needs `QML_XHR_ALLOW_FILE_READ=1`; the npm scripts set it.
- **No test QPA ever deactivates a window.** Under offscreen, xcb and wayland
  alike, `requestActivate()` on a second window is a no-op and both report
  `active`. Anything that depends on a window losing and regaining focus is
  measured in the live window only: focus a window, hop away and back with
  `hyprctl dispatch 'hl.dsp.focus({ direction = "left" })'`, then F12.
- **The `--inspect` dump describes the one scene in the window.** F12
  re-dumps live; a control-strip click dumps after the scene settles.

## Surface ladder and borders

One ladder, written in WCAG contrast against `background`. Every rung is
`Style.lift(surface, by)`, so a theme tunes `surface` once and the rest
follows; hand-tuned tokens drifted until raised sat at the resting value.

| Rung | Contrast | Role |
| --- | --- | --- |
| background | 1.0 | the shell, the ground under everything |
| `surface` | 1.2 | a component's resting body; the one hand-set colour |
| `surfaceRaised` | +0.2 | a layer above the shell: popup, dialog, capsule |
| `surfaceHover` | +0.4 | hover of a body that cannot grow (text, rows) |
| `outline` | +0.8 | pressed where growth is impossible; dividers, tracks, the empty toggle's rim |
| `accent` | | selected, focus, primary fill |

- `Style.tone(base, hovered, pressed, selected, enabled, accent)` is THE
  state matrix and `Surface` is the Rectangle that binds it; a component's
  body is one `Surface` (or one `tone` call) and never its own ternary. Four
  components each wrote their own and disagreed on the selected tint.
- Hover is a lift of one step above the layer the item lies on. An item on
  a raised layer hovers one step above raised. Controls that can grow keep
  growth (`StateLayer`); tint is for what cannot scale.
- An inactive track (progress, meter, ring, slider) is `outline`, a line,
  never a body's rung; `surfaceHover` means hover and nothing else.
- Selected is identity, not a lift: `accent` at 12 % over the layer plus
  accent content (text, glyph). A toggle with its own fill (Switch, Checkbox,
  Radio) is selected as solid accent. Selected plus hover adds the step.
- A border encodes a fact colour cannot, and there are five: a failed
  value (danger), the shape of an empty toggle, containment of a foreign
  colour (a swatch may equal the ground), the focus ring outside at a half
  step, and a physical object the person knows from the world (a key cap in
  `Kbd`, the convention GitHub, MDN and shadcn share). Layers are separated
  by a rung, never by a line.

## Component laws

Earned, each from a specific failure. Break one and name which.

- **A type is a concept, never a surface.** `OsdSlider` and `LevelBar` were one
  slider wearing two names because two surfaces asked for it; they differed in
  three numbers. If a name contains where it is used, it is wrong. A library
  that grows a type per call site stops being a library.
- **A component knows its PROPORTIONS; the absolute size comes from the
  theme's size table.** Every sized type has one absolute number
  (`knobSize`, `thumbSize`, `fieldHeight`) and everything else is a ratio of
  it. That number is `Style.size("<Type>", size)`: `size` is a preset NAME
  (`"md"` by default) and the theme owns the table, `sizes.<Type>.<name>` in
  `tokens/deep-night.json` as the default and `Style.backend.sizes` as the
  consumer's, who adds `xl: 40` and writes `size: "xl"` (the Chakra, Radix
  and Ant model). An unknown name falls back to `md` and warns once. The
  number stays settable directly as the escape hatch. Never an enum with
  token mapping inside the component: this is a general library, not one
  desktop's kit.
- **One scale per instance, and everything connected to the component
  scales with it.** `s = Style.size(Type, size) / Style.size(Type, "md")`.
  A component is designed in `md`; every other measurement is its md value
  times `s`, snapped to its own scale so no value lands off the system:
  text through `Style.textNear`, glyphs through `Style.iconNear`, spacing
  and insets through `Style.rhythm`. The label, the glyph in a thumb, a
  slot action, the gap to the label: all of it. Radius, the focus gap and a
  1px border do not scale (M3 keeps radius per component, not per size).
  Sizes that grew only the area left a huge control with a tiny glyph and a
  tiny label, which read as two components.
- **The bigger the instance, the calmer it is: overhangs, growth and joins
  scale SLOWER than the body, and what must stay hidden is hidden by
  geometry, never by a constant.** A slider track of "thumb minus one unit"
  was 0.83 of the thumb at md and 0.9 at lg, and the fill's rounded end (its
  shoulders sit 0.707 x thickness from the thumb's centre) peeked out beside
  the big thumb as a second pill. Two thirds of the thumb keeps every size
  under the 0.7 line. Derive such ratios from the geometry that has to hold
  and write the proof in the comment.
- **No numbers in a component.** Every measurement comes from `Style`. Where a
  scale had a gap, components filled it by typing a literal, and 16, 18 and 22
  all became "the small icon" in three files. A call site that needs a different
  value passes it as a property; the library keeps one default.
- **Never read `Tokens` from a component.** Read `Style`. A value taken from
  `Tokens` is a value the consumer cannot retheme, which is two sources of
  truth wearing one name.
- **Every interactive component defines all five states**: rest, hover, press,
  focus, disabled. `StateLayer` owns them and the component FORWARDS them.
  Owning a state the component cannot express is the same as not having it.
  Focus was missing for a keyboard-first shell, which meant a person driving by
  keyboard had nothing telling them where they were.
- **Content goes in slots, not properties.** What sits above, below or inside a
  control is the consumer's business. A slider that hardcodes an icon under its
  track is a slider that has to be rewritten for the second surface. An empty
  slot takes no space.
- **A component never manages its own dismissal.** It reports `hovered`; the
  surface holding it decides what that means. Otherwise the component has to be
  told about every surface it might ever sit in.
- **One fact, one place.** A rule components need but cannot see (who is
  driving, whether a hover may claim a selection) lives in one singleton the
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
  height fed its own height.
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
- **A host answers the component; it never stands in for it.** A unit, a story
  adapter and a flow host exist to ANSWER what a component reports and to drive
  its actions. The moment one decides a behaviour — when to close, what a grace
  period means — it has replaced the component, and a green flow then proves
  only that the replacement works: the Workbench adapter re-derived the
  rollout's keep-open test, so a passing dismissal flow tested the
  re-derivation and neither `EdgeScene` nor `Rollout`. Drive what the component
  reports; when it does not report what the host needs, the component is what
  is incomplete. A step a host cannot execute must FAIL and name itself — a
  fixture that reports success without doing the work hides every real gap
  behind it, and that is how a provider shipped a six-step host for a
  thirteen-step language with nothing noticing.
- **The library's vocabulary is binding on a host, pointer facts included.**
  `ScenePointer` exists so nobody re-derives `inside && contains(position)`.
  A host that needs a pointer a test cannot fake asks for an injection point
  shaped like the pointer, never for a second implementation of the geometry.
- **A type that reports intent but offers no way to receive it forces its
  consumer to invent the missing half.** Ours can only read a host's `hovered`
  or run its own handlers, so the rail answered "this entry is open, therefore
  lit" with 130 lines of geometry; caelestia lets an external owner assert a
  state into `StateLayer` with one boolean. See `docs/BACKLOG.md`.
- **Reduced motion shortens a DURATION and lengthens a PERIOD.** A one-shot
  transition calms by getting shorter; a loop calms by getting slower.
  Shortening a spinner's period makes it whirr.
- **A hover reader belongs on the ANCESTOR of the surfaces, never stacked
  with them.** Measured with real pointer events: a `HoverHandler` on a
  sibling item BELOW the surfaces never sees the pointer; on a sibling
  ABOVE it sees the pointer and steals hover from everything underneath;
  declared on the ancestor both work. `blocking: false` changes neither
  sibling case. `ScenePointer` exists so this is a type with the rule in it.
- **A component that hands its state upward is dead in a preview that does
  not host it.** `Slider` emits `moved` and never writes its own `value`,
  because the host owns it. A unit that did not answer `moved` showed a
  slider that ignored the pointer, the wheel and every arrow key.
- **The width a component asks for must include the inset it then gives
  away.** `ListRow.implicitWidth` reported its body's span while the body
  loses two insets to its own margins; the first caller to trust natural
  sizing had its text truncated.
- **One keep-open rule for every rollout, not one per surface.** A rollout
  is open while the pointer is inside its hitbox, which is larger than the
  item and covers the corridors a hand sweeps through, plus a delay after
  the pointer leaves. `Rollout` reports `triggered`, `hovered`, `keepOpen`
  and `wantsOpen` and never closes itself; the surface decides. Two
  surfaces each invented their own version of this and both were broken.
- **A name that lies is worse than a long name.** `held` read as holding a
  mouse button. `hovered` is the pointer being in the hitbox right now, and
  `keepOpen` is that plus the delay.
- **One type may have several purposes; its unit changes the whole
  composition.** Plain text, search, password and number are one `TextField`.
  A purpose switch changes input semantics, leading glyph, trailing action
  and sample value together. Changing only `inputType` left a magnifier on a
  password field.
- **An action never adds padding or footprint; the owning component decides
  spacing.** A slot glyph's layout footprint is the glyph's own width and a
  clickable label's is its text. A larger hit box overflows the footprint
  (`StateLayer` centred, at least `Style.iconLg` each way) instead of growing
  it. A slot that grew to fit a control's padding moved the text column with
  the purpose; a label that grew to its hit box moved a slider's whole track
  the moment it became clickable.
- **A generic focus ring never erases a stronger semantic state.**
  `StateLayer`'s accent ring sat above `TextField`'s danger border, so a failed
  field stopped looking failed exactly while a person focused it to repair
  the value. The host passes the semantic colour through `focusColor`.
- **Focus shows whenever it is held, however it arrived.** The ring read
  Qt's `visualFocus` and a hand-kept mark of "this focus came from a click",
  so a click never rang and a window that lost and regained focus rang out
  of nowhere: Qt drops `activeFocus` from every item when the window goes
  inactive and gives it back with no route attached. `activeFocus` is the one
  fact; guessing the route is a component doing the host's thinking.
- **The focus ring sits OUTSIDE the painted body at a half-step, concentric,
  under anything that overhangs.** Gap `Style.spaceTight`, outer radius =
  the body's radius plus the gap (the reverse of `Style.childRadius`), z
  below a thumb or glyph that stands on the body. Sized to a slider's grown
  thumb the ring floated off the bar; flush on the bar it vanished on a full
  accent track (WCAG 2.4.13 wants 3:1 against the adjacent colour, and M3,
  Radix and Fluent all keep the indicator outside with a gap for that
  reason). A ring around the track, not the handle: the handle moves.
- **A resting surface reads at 1.2:1 against the shell background; hover
  and any highlight sit 0.4 above the rest.** The text box surface sat at
  1.05:1 and an empty field was invisible; 3:1 (the rubric's line) shouted.
  Judged in the window at 1.2 (`surface`) with hover at 1.6 (`surfaceHover`):
  visible, quiet, and the lift still reads. WCAG contrast ratios, computed
  against `background`, are the unit; a new surface token states both
  numbers before it lands in `tokens/deep-night.json`.
- **The cursor describes the region under it, not the outer component.** The
  editable body stays I-beam, a trailing action is a hand, and a leading
  action states its cursor explicitly.
- **Reveal changes visibility, never input semantics.** A password reveal
  keeps `inputType: "password"` and its sensitive-data hints; it changes only
  `passwordVisible`.
- **Invalid input is a fact; failed is a host verdict with copy.**
  `acceptableInput` reports the validator, while `failed` is set by the host
  that can explain what failed in `Field`. Return and a clickable submit
  glyph both call `accept()`; keyboard-only facts such as `selectionClaimed`
  stay on the keyboard route.
- **A text root paints under its own padding.** `T.TextField` scrolls long
  text left under `leftPadding`, which is where a leading slot sits. A text
  control with slots is a `T.Control` with a clipped `TextInput` content
  item, the shape `T.SpinBox` uses.
- **A text box's preferred width is a CONSTANT, never content-derived.** Long
  values scroll inside the clipped column; the box reports one fixed resting
  size.
- **Disabled dims by colour, never by opacity on a composite.** Opacity on a
  control applies to each child separately, so a translucent thumb shows the
  translucent fill through it. `Style.disabled(colour)` blends each colour
  toward the background opaquely and the layers stay layers.
- **A one-shot position animation is REMOVED under reduced motion, not
  shortened, and never runs during a gesture.** A slider's job is to sit
  where it was put.
- **One label element names a control from outside.** `Field` puts
  `ControlLabel` above a text box and `Slider` puts it on any of its four
  sides; content INSIDE a control (a thumb's glyph or reading) is the
  control's own. Two label rows with two type roles were one label wearing
  two styles.
- **One type, one or two thumbs.** `Slider` stands on `T.RangeSlider` and a
  plain slider parks its low thumb; a second `RangeSlider` type would have
  been the same slider wearing a second name.
