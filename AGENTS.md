# qsm-shell

- Build production QML before tests, documents, fixtures, or abstractions.
- A feature is complete only when real QML runs and its visible or interactive
  result has been checked.
- Do not add JavaScript models of QML behavior, expected-red tests, source-shape
  tests, documentation gates, or new manifests.
- Add one focused regression check only after a real behavior works.
- Keep `qsm-desktop` policy, services, persistence, and compositor integration
  out of this library.
- Native QML is the only place a component is looked at. `previews/` plus
  `npm run capture` renders the real type offscreen; the live consumer is the
  final judge. There is deliberately no second rendering of any component in
  another language, because a mirror that shows the right colours and the
  wrong shape is worse than no mirror.
- Design every meaningful resting, hover, pressed, focused, selected, disabled,
  loading, empty, and error state that the component actually supports.
- Pointer and keyboard routes must perform the same action, keep focus visible,
  and provide immediate feedback. Motion communicates state and respects
  `Style.reducedMotion`.
- Review native captures for hierarchy, spacing, contrast, typography, and
  target clarity before calling a visual change complete.
- Use `tokens/deep-night.json` for shared values and regenerate outputs with
  `npm run tokens`.
- Comments explain non-obvious mechanics only. Git history, task history, and
  restatements of code do not belong in source comments.
- Keep durable documentation to `README.md` and `docs/BACKLOG.md` unless a
  genuinely irreversible architectural decision needs a short record.
- Do not claim completion from mocks, lint, screenshots of different surfaces,
  or tests that expect production to fail.
- Run `npm test` before handing work back.

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
