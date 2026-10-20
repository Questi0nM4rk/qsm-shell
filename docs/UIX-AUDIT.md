# UIX audit handoff

The library is audited before the desktop. This file tells the next agent what the work is, what
is already true, and what the owner decided. The authoritative plan is
`openspec/changes/uix-component-audit/` (proposal, design, spec, tasks); the tracker holds the
state. This file is the orientation, not a second plan.

## What the owner asked for

A complete review of every qsm-shell component against the installed qsm-uix guidance, then a
real redesign of the desktop. Every component needs a deliberate task, its controls, its
interaction contract, its visual hierarchy and its motion. A working story is not enough.

The owner approved a full redesign, including changing the shared silhouette. That is permission
to change the visual identity, not acceptance of a particular replacement.

## What is true now

- The library exports 52 types; the catalog holds 60 story keys, several aliasing one type.
- The desktop provider holds 13 stories of composed surfaces.
- `qsm-uix` is installed and its skills are the method: `ui-design`, `ui-audit`, `ux-audit`,
  `a11y-audit`, `review-animations`, `desktop-ui`, `qml-ui`.
- The Workbench can capture the current state of an explicitly selected session, in preview scope
  or window scope, without restarting it, without moving the system pointer and without a
  compositor. See the command block in the change's `tasks.md`.
- The offscreen pipeline does not rasterise `SvgIcon` glyphs, so glyph-bearing types photograph
  empty. That is a known pipeline limit, recorded in `AGENTS.md`, not a component defect. Visual
  evidence for glyphs needs a real window on workspace 10.

## Owner decisions that bind the work

| Decision | Consequence |
| --- | --- |
| Audit the whole library first, not only the desktop's subset | 52 types, one record each |
| Repairs happen one item at a time, with owner acceptance | No batch of component changes |
| Desktop integration follows library acceptance | Desktop work stays blocked |
| Full redesign is allowed, including the silhouette | Old project rules are not a defence against a finding |
| Minimum tooling: only what blocks this audit | No general Workbench rebuild, no evals, no review loops |
| Hitbox mathematics belongs in every component record | Each record carries geometry and pointer paths |
| Never claim a human average | Modelled trajectories are labelled as assumptions |

## What a record must contain

One section per type in `docs/components/<Type>.md`, added to the existing record:

- purpose and consequence, the task the type finishes
- expected public controls, valid states, and which of them are implemented
- pointer, keyboard, wheel, focus and accessibility routes, with the real ones named
- sizes, empty and long content, failure and cancellation
- visual roles and palette pairs, motion and its reduced-motion form
- pointer geometry: input shape apart from painted size, origin assumptions, distance, width
  model, difficulty in bits, landing tolerance, neighbouring interference, and for popups the
  trigger-to-panel corridor and its timing
- findings separated into source-backed defects, redesign proposals, source conflicts and
  hypotheses
- evidence separated into source-reviewed, runtime-exercised and owner-accepted

`docs/USAGE.md` holds the shared method and one coverage row per type. The README links to it.

## How the work is judged

A finding without a number is an opinion. Every row in a record names its evidence: a capture, a
tree line, a file and line, or an explicit statement that the route is not testable. A blank
capture is never evidence that a control is missing. A semantic action that runs is never
evidence that a click, a key press or a focus ring works.

## Where things are

| Place | Owns |
| --- | --- |
| `openspec/changes/uix-component-audit/` | The plan, the spec and the step order |
| `docs/components/<Type>.md` | One type's contract, findings and evidence |
| `docs/USAGE.md` | The shared method and the coverage index |
| `docs/BACKLOG.md` | Open findings only, one line each |
| `../qsm-workbench` | Session capture and native input mechanics |
| `../qsm-desktop` | Production surfaces, services, policy; blocked until the library lands |

## What not to do

Do not start component repairs during the audit. Do not edit the desktop. Do not restart the
production shell. Do not record a check as owner acceptance. Do not invent a spacing, contrast
or size threshold and call it a standard: cite the source, or state the design source's own
value.
