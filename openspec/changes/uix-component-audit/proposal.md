## Why

The owner needs a complete UIX review before accepting component repairs or desktop integration.
Existing stories and short records do not establish input reachability, visual polish or forgiving
hit geometry across the library.

## What Changes

- Reconcile exported types, story aliases, component records and current desktop use.
- Extend `docs/components/<Type>.md` with intended behavior, current evidence and redesign findings.
- Add per-target hitbox and pointer-path mathematics, explicitly separating models from user data.
- Keep one shared audit method and coverage index in `docs/USAGE.md`.
- Use the installed Workbench for requested isolated runtime evidence. Missing capture/input
  capability is a named gap, not a pass.
- Complete the full audit before component repairs. Redesign, including the silhouette, is
  permitted but is not implemented by this audit change.

## Capabilities

### New Capabilities

- `component-audit`: complete, source-linked per-component design and evidence contracts.

### Modified Capabilities

None.

## Impact

`docs/components/*.md`, `docs/USAGE.md`, and open findings in `docs/BACKLOG.md`.
No production component, theme, shader, service or compositor change. No dependency installation.
Workbench session capture is owned by its separate `session-render-capture` change.

## Critiques

- Devil's advocate: a generic checklist could impersonate a real audit. Resolved by per-target
  source/state citations and separate source-reviewed, runtime-exercised and owner-accepted status.
- Future archaeologist: numerical averages could be mistaken for measured mouse behavior. Resolved
  by preserving origin assumptions, model choice, units and evidence gaps in each component record.
- Scope sniper: an audit could turn into an unattended redesign or a tooling rewrite. Resolved by
  excluding component repairs and limiting tooling work to independently specified blockers.
