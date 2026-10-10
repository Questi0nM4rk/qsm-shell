## Context

ControlLabel is a compact caption that optionally becomes an action. Its
`activate()` and pointer route exist, but keyboard and accessibility activation
do not. Slider's label emits `labelClicked` directly and is absent from its
four enumerated actions. SoundChannel bypasses the label for programmatic mute
and searches its children despite the existing readonly `labelItem` seam.

The owner has accepted the base component set. This change repairs one operation,
not its appearance. `AGENTS.md` forbids TDD and static/source-shape assertions;
the owner's current request explicitly authorizes focused behavioral checks.

## Goals / Non-Goals

**Goals:** the same optional label operation is reachable by Tab/Backtab,
pointer, Enter/Return/Space, accessibility and a stable callable Action. Disabled,
caption and empty cases refuse it. Host state remains host-owned.

**Non-Goals:** shader/motion/layout redesign, library service policy, another
catalog, generalized command transport, unrelated component repairs or production
restart. Desktop adoption has its own companion change.

## Decisions

1. Preserve caption/action duality and the existing visual footprint. Use a
   `T.Control` base for this hybrid label with explicit guarded activation, as
   the existing IconButton does; there is no native combined caption/action
   template. A passive caption is not a disabled button. Do not add padding or
   replace the row composition with a styled button.
2. `ControlLabel.activate(): bool` returns whether it emitted `clicked`. All
   routes call it. Its Action has `objectName: "activate"`; availability is
   enabled, clickable and nonempty. Only actionable labels enter the Tab chain.
   Space/Enter/Return use one dispatcher, suppress auto-repeat and cancel a held
   activation on focus/availability/content loss. StateLayer paints focus and
   keyboard press without adding layout space. Programmatic activation never
   synthesizes a key or changes focus.
3. Caller-owned `accessibleName` defaults to visible label text. Actionable
   labels expose Button semantics and `Accessible.onPressAction`; passive labels
   remain supporting caption text. Icon-only action hosts provide meaningful
   names, not icon filenames. No new global shortcut belongs in the library.
4. `Slider.activateLabel(): bool` emits `labelClicked` exactly once when enabled,
   labelClickable and nonempty. ControlLabel's clicked intent and the appended
   Action call it. Add `labelAccessibleName` defaulting to labelText. Existing
   four actions gain stable `objectName` identifiers: `increase`, `decrease`,
   `minimum`, `maximum`; append `activate-label` without changing their order.
   Thumb arrows and range navigation are unchanged; label focus adds a distinct
   reachable action rather than overloading a level key.
5. The Slider unit hosts a coherent audio/mute purpose when the label is an
   action, records the resulting muted state and does not change the stored
   level merely to mute. Keep its existing level/range API. SoundChannel exposes
   its actual `slider.labelItem` and routes toggle-mute through activateLabel;
   its existing host callback alone changes mute. Provider dispatch uses named
   function dictionaries and reports disabled refusal truthfully.
6. Verify the actual QML through focused input/host checks and existing affected
   flows, not a JavaScript model or coverage target. Strategy B: one sequential
   implementation segment, then requested checks, then owner review. No expected
   RED loop or full-catalog sweep; project rules override generic TDD choreography.

## Risks / Trade-offs

- Added action tab stop changes traversal only where a label already performs
  an operation → check entry/exit and caption/disabled skipping, retaining thumb stops.
- Key cancellation could leave a press latched → exercise focus loss, disabled,
  caption and empty transitions while a key is held.
- Icon-only names are host knowledge → wire sound examples and companion desktop
  hosts explicitly, never guess a mute consequence in the library.
- Offscreen input is not compositor focus or screen-reader speech → report it
  separately; do not grab a production window or claim owner acceptance.

## References and migration

Caelestia `components/controls/StyledSlider.qml` uses the Qt template for slider
behavior; `ButtonBase.qml` exposes state/intent separately from service policy.
WAI-ARIA APG Button Pattern requires a named action, Enter/Space and retained
focus when activation does not change context. Qt Quick Accessible/Keys supply
the native equivalents, not web markup. Existing Style/StateLayer sizing and
focus tokens win; no new tokens or aesthetic direction are introduced.

Revise ControlLabel/Slider records first, implement the shared route, update its
existing provider hosts, verify it, then let the separate desktop change consume
it. Preserve all unrelated dirty work; no commit, release or archive is authorized.
