## Context

`Rollout.qml` uses growing-contour geometry as its only attached contract. OSD,
all rail entries and nested details, panel/session, ModalHost consumers and attached
notifications adopt it in source without a geometry selector. The owner accepted
the earlier live OSD's look and behaviour and requested consolidation; this is not
evidence for the rewrite or all nested, fullscreen and input routes.

The shared geometry and library example are source-implemented; runtime review
remains pending. The owner authorizes coordinated source migration and removal
of attached travel without waiting for each caller's live review. This does not
authorize tests, validation, capture or restart. Superseded travelling artifacts are historical
material, never a competing instruction or completed implementation record.

## Goals / Non-Goals

**Goals:** one reusable source-attached expansion; a small caller API; stationary
full-size content; coherent frame/parent joins, input and terminal handoff; reuse
the existing renderer and owner-led review loop.

**Non-Goals:** arbitrary QML-item silhouette extraction; a second expansion type;
services, compositor policy, focus management or dismissal decisions; notification
row-animation redesign; new motion/palette tokens; automatic testing, captures or
desktop restarts. Detached fullscreen presentation is not a frame expansion.

## Decisions

### One type and two owners

Keep `Rollout`. It is the producer of reveal geometry, placement, clip/input facts
and hover/grace. `ShellBorder` renders the merged source and expansion through its
existing registry and shader. A desktop wrapper supplies content and host-owned
intent and answers reported facts. Rejected alternative: `ExpandingItem` alongside
Rollout, which would duplicate lifetime, placement and geometry.

### Source means a registered silhouette, not QObject parentage

A source is the host's frame band or `parentRollout` in that same host. A content
Item placed inside Rollout is not the source silhouette. A nested Rollout can be a
scene sibling so the parent's clip cannot cut off its expansion. A parent link
names the semantic source; the existing child link reports hover/seam facts.

For frame sources, resolve band depth from `host.leftEdge` on left and `host.edge`
on the other sides, respecting placement bounds. Preserve `edgeInset`,
`edgeInsetH` and `edgeInsetV` as explicit overrides. Registry-only injected hosts
without band properties fall back to `Style.frameThickness`; desktop constants
must not enter the library. Parent sources resolve from the full settled body
rect in host coordinates, not from the changing viewport width/height. Explicit
source placement/size changes may move the seam; reveal progress alone cannot.

### Full content and aperture are separate geometries

Keep required caller-supplied `bodyWidth`/`bodyHeight`, denoted `W`/`H`, and default
content in a full-size slot. Expose a readonly `contentItem` alias to that slot.
Do not infer preferred dimensions from clipped `childrenRect`; this preserves ADR
0002 and avoids a size feedback loop. Padding reserves the content inset; a
consumer accounts for its focus rings, grown controls and content overflow.

Let `p = clamp(1 - offsetScale, 0, 1)`. A horizontal aperture is `(W*p, H)`; a
vertical aperture is `(W, H*p)`. In local aperture coordinates the full body is:

| Origin side | Full body x | Full body y |
| --- | --- | --- |
| left | `0` | `0` |
| right | `apertureWidth - W` | `0` |
| top | `0` | `0` |
| bottom | `0` | `apertureHeight - H` |

The aperture grows away from the source wall. For a right source at `wallX`,
`root.x = wallX - apertureWidth`, so full body x in host coordinates is always
`wallX - W`. The corresponding bottom result is `wallY - H`; left/top body origin
stays on its wall. Cross-axis anchor centring and bounds nudge remain independent
of reveal. Body dimensions may change when the host requests a new size, not as a
side effect of progress.

Rejected alternative: counter-translate content in each desktop wrapper. The
full-body slot owns the coordinate rule once.

### Expand the union; do not paint another surface

For attached expansion, `silhouetteRect = viewportRect` before registration.
Source-side corners are squared; free radii clamp to
`min(Style.rolloutRadius, apertureWidth/2, apertureHeight/2)`.
QML and shader deformation are identity. No attached goo sampler, independent
content scale, extra rectangle, border sink or fade is part of reveal.

Keep the existing origin masks, non-origin edge snapping, capped frame welds,
parent/child corner coverage, exact full-span seams and overlap. A short child
keeps its exposed parent edge and T-junction; a full-span child must not invent a
line or dent at the seam. The shader owns these union/fill/lighting calculations,
not placement or lifetime. Do not change shader formulas merely to promote the
existing extrusion. If a nested-source defect requires a change, amend the exact
formula in `docs/12-mechanism.md` first and rebuild its `.qsb` with the `.frag`.

### Intent, input and terminal handoff remain explicit

Retain `shouldBeActive`, `suppressed`, `triggerAreas`, `hoverAreas`, `hovered`,
`keepOpen`, `wantsOpen`, `animating` and the current geometry observables.
Rollout never writes host state or manages dismissal. It has no user action or
keyboard/screen-reader role of its own; content controls retain their semantics.

Keep near-settled viewport input registration, but withdraw the Rollout's own
input region on semantic close/suppression, not only when paint disappears.
Wrappers disable outgoing actions immediately while retaining their visuals.
`registerHitRect: false` lets modal hosts retain their separate catch-region
policy; the library does not create a full-screen input mask or focus policy.

Retain content identity and dimensions through retract. At zero aperture depth,
outness is zero and the slot is neutral for fill, rim, existing stroke gate and
lighting before removal. No completion timer or later border restoration. Reset
or suppression cancels pending animation/grace without activating controls.

### One size-animation owner and existing motion tokens

Use existing small/large curves and durations without overshoot; reversing intent
retargets current progress. Reduced motion uses the existing reduced durations and
no attached deformation. `animateBodySize` remains true for target dimensions and
false when content already supplies animated extents. Notification row entrance,
eviction and lifetime stay inside NotificationStack; expansion cannot add a second
content animation or size lag.

## Risks / Trade-offs

- A renderer slot alone cannot identify an arbitrary container's contour → limit
  sources to the frame and registered parent Rollout; no silent arbitrary-Item API.
- A nested viewport used as an origin makes the child drift → use full settled
  source geometry and host coordinates, independent of QML clipping ancestry.
- An input aperture could stay live while content retires → gate registration on
  intent and retain the existing wrapper-level action withdrawal.
- Broad default promotion can change unseen surfaces → account for every attached
  caller's placement, lifetime and size owner before removal; retain detached
  presentation and do not claim acceptance from source review.
- Stationary content is still allowed to reflow when target size changes → define
  invariance relative to reveal progress, not an impossible permanent screen lock.

## Migration Plan

1. Retire old travelling artifacts as superseded; carry forward the still-valid
   seam, hover, lifetime and hidden-field laws in the new contract.
2. Keep the shared geometry/source defaults, full-size `contentItem` and existing
   sound-settings unit. Execute inline, sequentially; decisions stay with the owner.
3. Coordinate source adoption across OSD, all rail entries and nested details,
   panel/session, ModalHost consumers and attached notifications. Remove comparison
   selectors and redundant frame constants; preserve deliberate composition insets.
   Retain the rail source until its child finishes retracting and size matching
   from full body extents rather than the reveal aperture. Retired controls disable
   on close/suppression; modal catch policy stays unchanged.
4. Promote expansion and remove `borderExtrusion` and attached travel/goo/settle
   branches. Detached-only motion/settle knobs remain compatibility, not an attached
   style selector. Rollout owns target-size morph; remove ModalHost's second sizing
   implementation. Already animated notification extents still opt out of morph.
5. Hand over one selected Rollout item and wait for owner judgement. No automatic
   catalog sweep, check or production restart; other consumers remain unaccepted.

Do not reset unrelated dirty work or restore superseded travelling requirements
as the canonical specification. Fix review feedback in the owning shared mechanism
or consumer boundary, not by reintroducing a permanent per-surface mode switch.

## Open Questions

No unresolved product choice blocks this target contract. Nested moving/resizing
source joins and fullscreen handoff remain implementation/review risks, not claims
of completed runtime verification. Automated checks need a separate owner request.
