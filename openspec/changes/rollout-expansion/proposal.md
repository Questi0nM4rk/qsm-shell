## Why

The owner prefers the live OSD's growing border contour to a travelling panel and
has selected the left Network popout as the second production example. Both
should become ordinary uses of one reusable Rollout, not permanent per-surface
exceptions with competing geometry contracts.

## What Changes

- Define Rollout as an expansion of its source container's registered silhouette:
  a frame band or a parent Rollout, not an arbitrary unregistered QML item.
- **BREAKING**: make growing-contour geometry the attached default and retire
  travelling-body selection, attached goo and independent content settle scaling
  after consumer migration. Keep the existing Rollout type and host-owned intent.
- Keep full content dimensions separate from the current clip/input aperture;
  preserve content size and source-relative position during reveal and retract.
- Derive normal frame insets from the rendering host; retain explicit overrides
  and generic anchor/parent placement, without compositor or desktop policy.
- Preserve shared hover/grace, input gating, reversible motion, size-animation
  ownership, shader seam rules and the hidden-neutral handoff.
- Retire the old travelling proposal as superseded without marking its open tasks
  complete or promoting its rejected geometry requirements into durable specs.
- Update normative mechanism and the current component record before code; prepare
  one coherent library example. The owner authorizes coordinated source migration
  of all attached callers and default promotion; live judgement remains one item
  at a time and does not follow automatically from that authorization.

## Capabilities

### New Capabilities

- `rollout-expansion`: source-attached silhouette expansion with stationary full-size
  content, automatic frame insets, shared lifetime/input facts and nested sources.

### Modified Capabilities

None. There is no durable OpenSpec Rollout capability; the superseded
`rollout-body-retract` delta was never promoted.

## Impact

Library `Rollout.qml`, its existing `workbench/units/Rollout.qml`, component and
normative mechanism records. `ShellBorder.qml` and `edgemelt.frag` remain the sole
renderer and retain their established field, weld and lighting formulas unless a
specific nested-source defect requires a documented correction. Any shader edit
requires its compiled `.qsb` alongside it.

Desktop OSD, rail, modals and notification wrappers are consumers; their bounded
integration scope is attachment, content retention, input withdrawal and removal
of geometry selection/duplicate size animation. No services, dismissal consequences,
Wayland masks, persistence, new component types, dependencies or timing tokens.
Shared geometry and the library example are source-implemented; current live
consumer source migration is authorized without a production reload.

## Critiques

- **Devil's advocate — "shader handles the rest" hides geometry ownership.**
  Addressed: Rollout still owns coordinates, clipping, input, progress and lifetime.
  A source is the frame or a registered parent, never an arbitrary Item; nested
  attachment uses its settled extent and does not inherit its clipping ancestor.
- **Future archaeologist — new normative intent could masquerade as shipped code.**
   Addressed: records distinguish source implementation from live deployment;
  superseded tasks retain their unchecked state. Old endpoint/seam guarantees are
  carried forward, not discarded with travel. OSD acceptance does not imply
  acceptance of every direction, nested source or Network input route.
- **Scope sniper — a generic container could grow into another surface framework.**
  Addressed: reuse Rollout and existing host registries, retain explicit body sizes,
  and add no arbitrary-shape engine, policy hooks, backdrops or automatic tests.
  Fullscreen presentation stays separate from attached expansion. No extra type or
  permanent style toggle is introduced.
