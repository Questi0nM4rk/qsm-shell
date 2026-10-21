# Production Goal

Deliver `qsm-shell` as a complete component library for Qt 6 and Quickshell
desktops: simple, minimal, fluid, visually coherent, judged in a real Wayland
window. It knows nothing about the applications that use it; they use its public
API and nothing else. Workbench is the tool that hosts and proves it, not a
second product.

`AGENTS.md` is the binding law for how work happens. `docs/BACKLOG.md` holds every
open item with the reason it is still open. This file says what the product is
and what comes next — nothing else.

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
  surface-named duplicate and no consumer policy inside the library.
- **Local**: no compatibility layers, no versioned public API, no generic web
  abstractions, no coverage-driven tests.

## The component set

`qml/QsmShell/Components/qmldir` is the set, grouped in `docs/USAGE.md`. Each type
has a record in `docs/components/<Type>.md`, a unit in `workbench/units/` and
story keys in `workbench/stories.json`. A type enters when a shell task needs it
and no existing type can take the role; it leaves when nothing needs it. `Style`,
`Motion`, `Interaction`, `Fuzzy`, the icons and the edge shader are runtime
support, not components.

## Next, in this order

0. **Full-library UIX audit, then owner-led repairs.** The owner wants every
   exported type reviewed against the installed qsm-uix guidance, with each
   type's record carrying its intended behavior, its real input routes and its
   hitbox and pointer-path mathematics. The audit lands first; repairs follow
   one item at a time with owner acceptance; consumers follow the library.
   Orientation `docs/UIX-AUDIT.md`, plan
   `openspec/changes/uix-component-audit/`, tracker `qss-9zk`.
1. **Keep the technical gates honest.** Repeat the full `npm test` gate only when
   requested; lint warnings remain. Checks run against a consumer are separate
   evidence, never acceptance.
2. **Live pointer parity.** Clicks, drags, wheel and focus judged in a real window,
   after waiting for the actual reveal, including repeated toggles. A passing
   check does not establish live hit testing or owner acceptance.
3. **Release readiness.** The owner's remaining backlog items, one at a time, in
   the order `docs/BACKLOG.md` lists them.

## Ownership

| Concern | Owner |
| --- | --- |
| Reusable components, intent APIs, style/motion, assets, shader | `qml/QsmShell/` |
| Story state, fixtures, controls, composed cases | library `workbench/` |
| Window, inspection, native driver, flow engine | sibling `qsm-workbench` |
| Services, persistence, compositor masks, focus policy | the consuming application |

A consumer installs its own theme through `Style.backend`; the harness never
acquires a consumer's palette or service policy.

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
