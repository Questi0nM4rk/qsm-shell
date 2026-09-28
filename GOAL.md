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
- Quiet: whitespace and surface elevation establish hierarchy; accent denotes
  selection, focus, or the primary action, never passive decoration.
- Durable: one concept has one type; slots hold caller content; no surface-
  named duplicate components or desktop policy in the library.
- Local: do not add compatibility layers, public-versioning work, generic web
  abstractions, documentation history, or coverage-driven tests.

## Scope

Prioritize the components imported by `../qsm-desktop/shell/`:

`Rollout`, `ShellBorder`, `ScenePointer`, `ListRow`, `TextField`, `Slider`,
`MonthCalendar`, `NotificationStack`, `NotificationCenter`, `ActionTile`,
`StateLayer`, `IconButton`, `Capsule`, `Card`, `Meter`, `StatRing`, `Sparkline`,
`EmptyState`, `ScrollCue`, `Divider`, `Prose`, and `SvgIcon`.

Finish the active family around a component when needed for a correct desktop
surface. Leave dormant types (`Dialog`, `Scrim`, `Skeleton`, `Popover`) alone
until a real surface requires them. `docs/BACKLOG.md` contains the remaining
open work only.

## Workbench Migration

`previews/units/` was a temporary shell-side harness. Retire it completely.
The workbench owns all component state hosts, controls, actions, stories,
compositions, flows, and live previews; qsm-shell owns only reusable production
components, their minimal behavior regressions, tokens, and provider-owned
catalog/adapter data. Do not add a new shell preview unit or migrate another
type into that directory.

Move one component family at a time: create its provider story and bounded
adapter mapping under `workbench/`, prove pointer/keyboard/wheel/focus behavior
in workbench, then remove the old shell unit and its duplicate preview code.
The workbench must render the real qsm-shell component, never a visual copy.

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

## Map

| Need | Location | Owner |
| --- | --- | --- |
| Production QML | `qml/QsmShell/Components/` | qsm-shell |
| Theme contract | `qml/QsmShell/Style/`, `tokens/deep-night.json` | qsm-shell |
| Provider adapter, stories, composition types, flow host | `workbench/` | qsm-shell |
| Behavior checks | `tests/units/tst_<Type>.qml` | qsm-shell |
| Component record and open items | `docs/components/`, `docs/BACKLOG.md` | qsm-shell |
| Story metadata, compositions, and UI | `../qsm-workbench/stories/`, `compositions/`, `qml/` | workbench |
| Composition and flow runners | `../qsm-workbench/compositions/`, `flows/`, `scripts/` | workbench |
| Real consumer surfaces | `../qsm-desktop/shell/` | qsm-desktop |

## Delivery Loop

1. Read the consumer call sites, nearest component, provider story, tests, and the
   matching Caelestia control before changing an API.
2. Write or reduce the component record to its durable facts: states, actions,
   size, tokens, motion, events, and deliberately unsupported behavior.
3. Implement the smallest vertical slice in `qml/QsmShell/Components/`.
   Every host-owned write is an intent signal or public function; pointer,
   keyboard, wheel, and programmatic routes call that one function.
4. Keep state hosts in workbench compositions or stories, never beside the
   component in qsm-shell. Add a scenario and metadata only when the state can
   be meaningfully inspected in workbench.
5. Drive the live window on workspace 5 with `compuse`; exercise the planned
   state trace, inspect it, then close the window. A screenshot proves only
   that a frame rendered.
6. Add one behavior regression check only if real behavior could regress.
   Delete or simplify tests that only assert private IDs, source shape, pixels,
   or duplicate an already-covered route.
7. Run focused workbench tasks, the relevant flow or composition, then the full
   validation gates before declaring a slice complete.

## Workbench Commands

Run from `../qsm-workbench`:

```bash
npm run workbench -- <story-key>
node scripts/task-runner.mjs capture <story-key> /tmp/<story>.png
node scripts/task-runner.mjs flow flows/examples/<flow>.json
npm run validate
```

Run the library gate from this repository:

```bash
npm test
```

Use flow JSON for a semantic or animated integration contract, not for every
static story. Components remain in qsm-shell; all interactive state hosts and
stories move to workbench compositions.

## Agent Handoff

Use `qsm-implementer` for one self-contained qsm-shell component slice at a
time. Give it the component record, exact owner files, acceptance behavior, the
relevant Caelestia reference, and verification commands. Use the workbench's
`workbench-implementer` only for workbench-owned QML, orchestration, metadata,
or runner changes. An implementer reports its diff and tests; the coordinating
agent reviews and integrates only intended changes. Use `qsm-runner` for noisy
full suites and `qsm-visualizer` only when a long audit needs human presentation.

Do not delegate final visual judgement blindly. The coordinating agent owns the
live workbench pass, source/consumer compatibility, and cleanup of the preview
window.

## Current Handoff

- Preserve the existing dirty worktrees and edits; they include ongoing
  component migrations and workbench infrastructure.
- `ListRow` now distinguishes unavailable from report-only rows and frees an
  empty trailing slot. Its behavior unit passes through task-runner.
- `MonthCalendar` uses a live-window-safe `MouseArea` wheel route and passes
  focused behavior checks.
- `Rollout` now maps fallback silhouette and registry rectangles into host
  coordinates, including nested hosts. Its unit and shell-border flow pass.
- Keep simplifying comments and docs when they merely narrate code. Preserve
  comments that record measured Qt quirks, geometry proofs, or a non-obvious
  library boundary.
