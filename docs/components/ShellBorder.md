# ShellBorder

The host a Rollout needs: the seven-call contract, the melt shader that paints
the band and every registered silhouette as one SDF, and nothing else. The
window, layer shell, input mask and every surface stay with the consumer; this
type never names Wayland, a monitor or a Region.

## Contract

- **Calls:** `registerBulge`/`unregisterBulge` (silhouette: rect, per-corner
  radii in CSS order, blend, deform, edge and seam bits), `registerRolloutRegion`/
  `unregisterRolloutRegion` (input rect), `registerFullscreenCapsule`/
  `unregisterFullscreenCapsule` (detached capsule; `paint: false` keeps it an
  input hole only), and the plain `fullscreen` property. Unregistering an absent
  id is a no-op. Registries are reassigned, never mutated.
- **Reports:** `bulgeEntries`, `paintedBulges`, `maskRects`,
  `fullscreenCapsuleEntries`, `fullscreenPaintEntries`. `entryFilter` (a
  predicate over ids) hides ids from every derived view, never from the raw
  registries. `pointer` is the consumer's `ScenePointer`, passed through to
  Rollout's `keepOpen`; null reports no hover.
- **Slots:** the shader paints eight silhouettes and eight capsules. A ninth
  silhouette or capsule stays registered and in the mask, is not painted, and
  logs `ShellBorder: ... is beyond the 8 painted slots` once when it arrives.
- **Geometry:** `leftEdge`, `edge`, `viewportRadius`, `meltSmoothing`,
  `edgeSnapReach`, `seamOverlap`, `band`, `edgeColor`, `edgeStrength`,
  `edgeFade`, `handle0` default to the `Style` frame numbers. A silhouette within
  `edgeSnapReach` of a band extends through it and squares its corners; a weld is
  capped at half the thinnest band it crosses; seam sides overlap their
  neighbour by `seamOverlap`.
- **No** pointer tracking, rollout behaviour, key, focus, role or content; it is
  chrome. Formulas: [`12-mechanism`](../12-mechanism.md) (normative, with
  `shaders/edgemelt.frag`).

## Expected

`shell-border` opens `workbench/units/ShellBorder.qml`: a full-viewport border
with a shown rollout. Controls show, hide and suppress it, switch windowed and
fullscreen, attached and detached, withhold its input rect, filter all
registrations, add and remove a capsule, and fill every silhouette slot.

## Measured

- Shown, hidden, suppressed, fullscreen (attached and detached) and filtered
  each paint a single stable picture; fullscreen toggling reloads no shader.
- Nine silhouettes: nine entries, eight painted slots, one warning.
