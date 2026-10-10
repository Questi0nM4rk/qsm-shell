> Superseded by `openspec/changes/rollout-expansion`. Historical proposal, not an active change or completed implementation.

## Why

The owner rejects a rollout close that looks like shrinking and disappearing.
The content moves, but the shader currently paints the narrowing clipping window
and shrinks its radii; it must instead paint the same full body moving under a
stationary border.

## What Changes

- Separate actual full translated silhouette from clipped viewport/input geometry.
- Use full-body radii and a shared full-body deformation/velocity pivot.
- Disable default content settle scaling; keep existing curves and caps.
- End attached travel exactly at the origin wall, with identity deformation and
  no shader contribution at zero outness; preserve the bare frame at the endpoint.
- Update normative shell mechanism, component record and desktop motion specs.

## Capabilities

### New Capabilities
- `rollout-body-retract`: constant-size translated silhouette during reveal/retract.

### Modified Capabilities
None.

## Impact

Shared Rollout QML and its registries; all attached consumers receive the correction.
No new desktop animations, timers or flags. Endpoint shader formula and compiled
artifact change together so hidden bodies cannot leave a frame-join remnant.

## Critiques

- Devil's advocate: a translated shader body might expand input. Addressed by
  keeping hit registration on the exposed viewport, not the full hidden body.
- Future archaeologist: content and shader pivots could drift. Addressed by the
  single normative body-centre contract and explicit native geometry properties.
- Scope sniper: new easing would hide the wrong geometry. Addressed by leaving
  durations/curves intact; change only representation and default settle scale.
