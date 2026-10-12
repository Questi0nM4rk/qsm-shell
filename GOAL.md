# Production Goal

Deliver `qsm-shell` as the complete local component library for one `qsm-desktop`
user: simple, minimal, fluid, visually coherent, judged in a real Wayland window.
Finish what the desktop actually uses before adding speculative types. Workbench
is the tool that hosts and proves it, not a second product.

`AGENTS.md` is the binding law for how work happens. `docs/BACKLOG.md` holds every
open item with the reason it is still open. This file says what the product is,
what is true now, and what comes next — nothing else.

## What "production-ready" means

Reusable QML with a small explicit API, host-owned state, real pointer/keyboard/
wheel/focus behavior, every meaningful state, constant natural geometry, semantic
`Style` tokens, and a story or composition that hosts the real component.

- **Dynamic**: interaction answers immediately and motion explains a state change.
- **Parity**: every operation is a function listed in `actions`; pointer, keyboard
  and callers share it, and focus is really reachable rather than merely declared.
- **Quiet**: whitespace and the surface ladder carry hierarchy; accent means
  selection, focus or the primary action, never decoration.
- **Durable**: one concept has one type, content arrives in slots, no
  surface-named duplicate and no desktop policy inside the library.
- **Local**: no compatibility layers, no versioned public API, no generic web
  abstractions, no coverage-driven tests.

## The production set — 31 types

Inventory comes from what the desktop actually declares in
`../qsm-desktop/shell/`, plus the dependency closure inside the library.

| Family | Components |
| --- | --- |
| Frame and reveal | `ShellBorder`, `Rollout`, `ScenePointer` |
| Input and actions | `StateLayer`, `ArmedAction`, `ActionTile`, `Capsule`, `IconButton`, `TextField`, `Slider` |
| Rows and scrolling | `ListRow`, `ScrollCue` |
| Notifications and calendar | `NotificationStack`, `NotificationCenter`, `MonthCalendar` |
| Readouts and identity | `Badge`, `Avatar`, `ColorSwatch`, `Meter`, `StatRing`, `Sparkline`, `Kbd` |
| Visual foundations | `Card`, `Divider`, `EmptyState`, `Prose`, `SvgIcon` |

Internal dependencies: `ControlLabel` (Slider), `NotificationCard`
(NotificationCenter, NotificationStack), `SelectionMark` (ListRow,
NotificationCard), `Surface` (ActionTile, TextField). `Style`, `Motion`,
`Interaction`, the icons, the edge shader and `fuzzy.js` are runtime support, not
components. Re-derive the table when desktop use changes.

## True now

- All 31 types have implementations, units and stories; the owner has reviewed the
  set. New types enter this scope when the desktop needs them.
- The desktop action menu is source-wired and exercised in isolation: audio with
  the output Slider under its row, Wi-Fi with the list and a row-attached password editor,
  Bluetooth through a service that owns each operation's lifetime, and repeatable
  Keep awake / Night light toggles. Every per-kind decision is a table keyed by
  `kind`, so a new kind adds an entry rather than another branch.
- The panel's tab group is the shared `Segmented` with opt-in Tab/Shift+Tab,
  clamped at its visible ends, and Down enters the tab content.
- `scripts/check-action-menu` drives five desktop stories through simulated Qt
  input and they pass. Production services are wired, but actual hardware success
  and owner acceptance are separate, still-open gates.

## Next, in this order

0. **Keep the technical gates honest.** The last requested `npm test` passed native
   interaction and unit checks, smoke and shader freshness, before the small Menu
   activation typing cleanup and glyph additions. Repeat the full gate only when
   requested. Lint warnings remain; desktop's
   isolated checks and production-only checks are separate evidence, not acceptance.
1. **Owner review of the action menu and the panel tab group** in the live window.
   Nothing below starts before that: keyboard reach, attached editors, repeated
   operations, NEIO/slash, the tab group.
2. **Live pointer parity** — clicks, drags, wheel and focus judged in a real
   window. Isolated launcher clicks now pass after waiting for the actual reveal,
   including repeated toggles and Wi-Fi confirmation; OSD pointer/key/action mute
   also passes. That does not establish live hit testing or owner acceptance.
3. **Real backends** — the same flows against the actual nmcli, Bluetooth and
   audio services. The isolated fixtures are proven; the hardware is not.
4. **Release readiness** — the owner's remaining backlog items, one at a time, in
   the order `docs/BACKLOG.md` lists them.

## Ownership

| Concern | Owner |
| --- | --- |
| Reusable components, intent APIs, style/motion, assets, shader | `qml/QsmShell/` |
| Story state, fixtures, controls, desktop-shaped cases | library `workbench/` |
| Window, inspection, native driver, flow engine | sibling `qsm-workbench` |
| Services, persistence, compositor masks, focus policy | sibling `qsm-desktop/shell/` |

The provider installs its own theme; the harness never acquires desktop palette or
service policy. Desktop operations use existing service and tool entry points and
share logic only where a second caller needs it — never a universal backend API,
a daemon, or a rewrite of view logic.

## Source hierarchy

1. `AGENTS.md` — binding component law and measured Qt/Wayland reality.
2. A design-system floor: semantic tokens, the 4px
   rhythm, one type and icon scale, designed states, purposeful motion.
3. `~/Clonned/caelestia/repo/components/controls/Styled*.qml` — the primary QML
   reference for wiring, geometry and interaction mechanics, translated into this
   library's `Style` and host-owned-state contract. Its services, palette and
   unrelated features are not copied.
4. `ui-design` to prepare, `ux-audit` and `ui-audit` only when the owner asks.

## Execution contract

One item at a time: write down what a finished item looks like, build it with the
shared components, host it in Workbench, hand it over with the states the owner
should inspect, and wait. A green check is evidence, never acceptance. Work lands
on `main`; a worktree is for parallel or throwaway work and its result is reviewed
and merged before the owner sees it.
