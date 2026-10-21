# 12 — Mechanism (normative reference code)

The implementation vocabulary the shell assumes. Code below is NORMATIVE: implementers use
these exact formulas/patterns; deviations require editing this file first.

The attached Rollout contract is source-silhouette expansion, specified in
`openspec/changes/rollout-expansion`: bounded progress, full-size slot access,
automatic frame insets, settled parent origins and immediate close input withdrawal.
There is no attached style selector. Detached fullscreen presentation remains
separate; shader code is unchanged. Source adoption is not live owner acceptance.
Superseded motion is retained in
`docs/archive/rollout-travel/`, not as an alternative target contract. Shader
composition formulas below remain unchanged.

## Render boundary and terminal handoff

Follow one body through `Rollout.qml` → `ShellBorder.registerBulge` / `snapToEdges`
→ shader uniforms → `edgemelt.frag` → visibility/registry removal. Record local,
host and rendered coordinates separately. For attached expansion, `silhouetteRect`
is the growing aperture and `viewportRect` is its exposed clip/input rectangle.
Full-size content is a separate stationary source-relative geometry. Registry
helpers may add paint-only non-origin weld contacts, but cannot move the source
wall, content or input as a side effect. A correct producer rect is insufficient
if a later helper normalizes it into a different shape.

The terminal comparison is almost hidden → hidden slot still present → slot
removed. At zero outness, composition preserves the incoming fill field,
existing edge gate and lighting, and effective deformation is identity. Removing
that neutral slot changes neither paint nor geometry; input already excludes the
hidden body. Preserving only the zero contour is insufficient because edge
depth uses the field's interior values and gradient. See
**Composition and fill**, **Edge separation** and **Reveal choreography** for formulas.

## Silhouette shader

One full-screen ShaderEffect per monitor computes the whole silhouette (band + all rollouts)
per pixel and fills it. Single pass; no per-shape draw calls.

The fill carries ONE paint on top: the edge separation, a slight line of tint exactly at the
merged silhouette's edge that fades smoothly inward into the fill (see "Edge separation"
below). It is not a border and not a stroke around a shape — the shell draws neither, and
nothing draws its own chrome. It is the union's own edge, painted from the union's own
distance, and it exists only on inner boundaries.

### Attached expansion

Growing contour is the attached target at the PRODUCER, not a registry shim or
second shader. `silhouetteRect` IS `viewportRect` before paint normalization;
free radii clamp to current aperture half extents. `effectiveDm00/01/11` are
`1, 0, 1`, and full-size content parks at its settled source-relative coordinate.
No attached goo integration or independent content scale/fade runs. A source is
the frame band or a registered parent Rollout in the same host, not an arbitrary
Item or inherited QML clipping ancestor. A fullscreen-detached capsule does not
pretend to expand an absent frame.

Use the same `registerBulge`, origin mask, blend and outness: one slot, one fill,
one pass, no extra rectangle or registry. Outness reaches zero before removal,
preserving the incoming fill field and lighting. No caller-specific geometry
selection is part of this contract.

The render chain to follow for one body is
progress → viewport/silhouette → registry → shader → hidden neutral.
`viewportRect` is the clip/input aperture and `silhouetteRect` is the contour
supplied to paint normalization. Trace both
through `ShellBorder.registerBulge` / `snapToEdges` → shader uniforms →
`edgemelt.frag` → visibility/registry removal, and confirm the terminal slot
present at zero outness contributes nothing before it is unregistered.

### SDF primitives

```glsl
float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float r) {
    vec2 q = abs(p - center) - halfSize + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Per-corner radii (tr, br, bl, tl): select the active corner's radius by
// quadrant sign before the standard formula.
float sdRoundedBox4(vec2 p, vec2 center, vec2 halfSize, vec4 r) {
    vec2 d = p - center;
    r.xy = (d.x > 0.0) ? r.xy : r.zw;
    r.x  = (d.y > 0.0) ? r.x  : r.y;
    vec2 q = abs(d) - halfSize + vec2(r.x);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r.x;
}
```

### Blend family (circular — arc fillets, radius k)

The blend deviates from `min(a,b)` only where BOTH inputs are < k; max blend depth at a==b is
`(sqrt(2)-1)*k`. The blend inflates the INTERIOR distance where both fields are inside (see
"Edge separation": the edge reads a normalised distance for that reason).

```glsl
float smin(float a, float b, float k) {
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}
```

### Band (frame) shape

The band is everything OUTSIDE the viewport. It has no outer boundary: the screen edge is not
a silhouette edge, so no field the edge reads may measure it (measuring it made open rollout
corners look cut off).
Every screen pixel is inside the band's reach, so the fill is unchanged.

```glsl
float dInner = sdRoundedBox(pixel, innerCenter, innerHalf, viewportRadius);
float dFrame = -dInner;
```

### Fixed frame — no border sink

Keep `dInner` unmodified while composing rollouts. Their origin fill continuation
already joins body and band; a receding wall would carve pockets around those
tails and add a second restoration motion when they disappear.

### Composition and fill

```glsl
// mergedSdf: start from dFrame and fold every occupied slot iteratively —
// Preserve the incoming field before composing each slot. Compose its full
// body and origin continuation into slotSdf with the existing union rules.
// Outness restores the incoming distance field, not merely the zero contour:
mergedSdf = mix(incomingSdf, slotSdf, outness);
float fw = fwidth(mergedSdf);                       // derivative AA: equal weight every axis
float alpha = 1.0 - smoothstep(-fw, fw, mergedSdf);
fragColor = vec4(fillColor.rgb * alpha, alpha) * qt_Opacity;
```

Constants, each a `ShellBorder` property with the library default in parentheses: the band is
`leftEdge` thick on the left and `edge` thick on the other sides (both `Style.frameThickness`
unless the host reserves more on a side, so the band on the attached side is whatever the host
states), `smoothFactor` is `meltSmoothing` (`Style.meltSmoothing`), the rollout radius is
`Style.rolloutRadius` (per-corner: 0 on the DECLARED attached edge(s) only — corner auto-join to
a second nearby band segment is the smin's job, not a radius zeroing), and the viewport rounding
is `viewportRadius` (`Style.radius2xl`). All shader coordinates are LOGICAL pixels; fractional
monitor scale is absorbed by fwidth-based AA.

`incomingSdf` is saved before this slot contributes anything.
The slot's melt radius still follows blend, independently of outness. At outness
one its established composition is unchanged; at zero the entire incoming field
is unchanged, including its gradient and interior depth used by the edge.
This is distance-field composition, not opacity on the painted body or its content.
It prevents slot removal from becoming a separate border-lighting recovery.

### Generic deformation inputs

Attached expansion supplies identity deformation. The generic shader still
accepts deformation inputs from other or detached producers;
support for those inputs does not require attached Rollout goo.
The shader evaluates each rect's SDF in the rect's undeformed frame by inverse-transforming
the sample point; a min-eigenvalue factor corrects the distance metric under non-uniform
scale. Registry rects are mapped through the rollout's parent, not the rollout itself, so
the registered center is the undeformed scene-space pivot. Mapping through the rollout would
already apply its Matrix4x4 and then the shader would deform that displaced center again:

```glsl
mat2 invDeform = mat2(invDm.xy, invDm.zw);          // CPU-precomputed inverse 2x2
vec2 tp = center + invDeform * (pixel - center);
float d = sdRoundedBox4(tp, center, halfSize, radii);
d *= max(minEig, 0.01);
```

### Uniform packing (8 slots + handles)

Qt cannot bind QML arrays to GLSL array uniforms — use NAMED per-slot uniforms:
`rect0..rect7` (vec4: cx, cy, halfW, halfH), `radii0..radii7` (vec4 per-corner),
`deform0..deform7` (vec4: the inverse 2x2, row-major), `param0..param7` (vec4: x = minEig,
y = melt-blend factor [0,1], z = packed seam/origin side masks, w = outness [0,1]).
Empty slot = zero rect (contributes nothing), and its param is `(1, 1, 0, 1)`.

Before packing, automatic edge snapping applies only to sides not declared in
the source-origin mask. A declared origin already has squared corners and a
shader fill continuation; normalization must preserve that source attachment.
Non-origin snapping remains paint-only and cannot change the input aperture or
full-size content placement.
For `snapToEdges(rect, radius, edgeBits)`, guard the existing gap comparisons:

```qml
// edgeBits is the incoming declared origin mask, before adding snap contacts.
if (!(edgeBits & 1) && x - root.leftEdge <= reach) { /* snap left */ }
if (!(edgeBits & 2) && rightGap <= reach) { /* snap right */ }
if (!(edgeBits & 4) && y - root.edge <= reach) { /* snap top */ }
if (!(edgeBits & 8) && bottomGap <= reach) { /* snap bottom */ }
```

Non-origin edge snapping, weld caps and neighbour seam overlap remain unchanged.
This paint registration never enlarges the separately registered input viewport.

`z` packs two side masks (1 left, 2 right, 4 top, 8 bottom): the low four
bits name seam continuations, the next four name the body's declared origin
sides. A parent can extend its seam toward a child still emerging, but cannot
extend fill there. Only origin sides extend fill through the body's source.
The shader reads only the origin bits (z / 16). A seam-only extension cannot remove an edge
computed from `mergedSdf`, and leaves a gap when deformation compresses the body away from
its origin.

```glsl
float ext = max(leftEdge, edge) + smoothFactor;
float originBits = floor(param.z / 16.0);
vec2 weldCenter = center;
vec2 weldHalf = halfSize;
// For each named side, extend by ext; left is shown here.
if (mod(originBits, 2.0) >= 1.0) {
    weldCenter.x -= ext * 0.5;
    weldHalf.x += ext * 0.5;
}
// tp is the original body's inverse-deformed sample, not a new transform
// around weldCenter: changing that pivot moves the exterior edge too.
float dWeld = sdRoundedBox4(tp, weldCenter, weldHalf, radii)
    * max(param.x, 0.01);
// Blend 0 keeps the parent/child union exact, not the child's frame join.
// Smooth only against the ORIGINAL frame, never the accumulated parent.
float outness = clamp(param.w, 0.0, 1.0);
float frameJoin = min(smoothFactor, minThickness * 0.5) * outness;
float attachedBody = param.y == 0.0
    ? (frameJoin > 0.0 ? smin(dFrame, dWeld, frameJoin) : min(dFrame, dWeld))
    : dWeld;
slotSdf = min(slotSdf, attachedBody);
```

This retains a straight full-span parent/child seam while a child touching a
second band gets that band's concave fillet. The frame join is capped at half
the thinnest band, the same weld-depth rule as the CPU registration. Its reach
also goes to zero with outness. A slot with outness zero contributes no body,
fill continuation or edge gate: skip it before merging its fields. Never
call this circular smin with zero reach as a substitute for exact min.

`w` is OUTNESS: how far this body has emerged, 0 hidden to 1 fully out. It is a different
fact from `y` and the two must not be conflated. `y` is the melt radius, and a caller may set
it to exactly 0 to ask for an EXACT union with a straight seam — a nested host flush against
its parent does this deliberately, while being fully out. Only `w` may gate the edge.
Handles are NOT slots: a circle handle is a dedicated uniform
rendered with a circle SDF — `length(p - c) - r` — folded into mergedSdf with the same smin.
Slot budget (worst concurrent case): popout + readout + notification rollout + one global
modal + calendar = 5 of 8; a peeked band is the band itself (no slot). Never exceeds 8.

### Edge separation

The edge is not a glow: it is a slight edge separation, so edges stay visible without a glow line.
The edge of the merged silhouette is a slight line of the edge colour exactly at the edge, then a
smooth gradient fading inward into the band colour over a short width. No grain, no noise, no
light term.

Uniforms: `edgeColor.rgb` is the edge colour, `edgeColor.a` the line strength (the share of
edge colour at the edge, 0..1), `edgeFade` the fade width in logical px. The profile is ONE
curve of ONE distance, so a bulge, a join, a rollout corner and a band side all get the same
edge:

```glsl
// Distance from the union's edge, in logical px, evenly on every side.
// mergedSdf is the smin-blended field the fill uses. It is a true distance only
// near a single wall: where two fields overlap, smin inflates the interior
// (smin(a, a, k) = sqrt(2) * a + k * (1 - sqrt(2))) and between facing walls it
// deflates it. Dividing by the field's own gradient length (first-order distance
// estimate, exact for any monotone function of a distance) removes both.
float gradLen = length(vec2(dFdx(mergedSdf), dFdy(mergedSdf)))
              / length(dFdx(pixel));                      // logical px per device px
float dist = max(-mergedSdf, 0.0) / clamp(gradLen, 0.5, 2.0);

float s = clamp(dist / edgeFade, 0.0, 1.0);
float w = edgeColor.a * (1.0 - s) * (1.0 - s) * edgeGate;  // steep first, long tail
rgb = mix(rgb, edgeColor.rgb, w);                          // before `rgb * alpha`
```

`(1 - s)^2` is the line plus the gradient in one curve: the edge pixel carries the full
`edgeColor.a`, the first pixels drop quickly so the edge reads as a line, and the tail eases to
exactly zero at `edgeFade` with zero slope so it joins the band colour without a visible end.

Why it is even. The distance is measured to the union's own boundary only: the band has no outer
boundary (see "Band (frame) shape"), so nothing cuts the profile where a rollout wall reaches the
screen edge, and there is no diagonal chop at an open rollout corner. Per-corner radii and the
melt fillets are already part of `mergedSdf`, so corners, bulges and joins use their own true
contour. The gradient normalisation fixes the two places the blended field is not a distance.
A bulge narrower than `2 * edgeFade` is painted entirely, which is why the fade stays short.

Cards use the same curve on a rounded box (`cardglow.frag`): a box's SDF is already a true
distance, so the normalisation is omitted there and the profile is the same line.

**Water law.** A body that has not come out yet has no edge of its own. A barely-out rollout
drives its melt radius toward zero, smin degenerates to a hard min, and the union keeps a full
boundary where the new body meets whatever it is emerging from — which the edge would then
draw as a line between them. Gate only the newly exposed boundary, never
the existing frame/parent boundary. Read the incoming field before this slot:

```glsl
const float seamReach = 6.0;
float outness = clamp(param.w, 0.0, 1.0);              // param.w, NEVER param.y
float nearThis = 1.0 - smoothstep(0.0, seamReach, abs(d));
float newBoundary = nearThis * smoothstep(0.0, seamReach, incomingSdf);
edgeGate = min(edgeGate, mix(1.0, outness, newBoundary));
```

At the incoming union's edge (`incomingSdf = 0`) the slot gate is exactly one.
As its exposed edge approaches that wall, the mask returns continuously to one;
zero-outness slot removal therefore cannot switch a dark frame edge back on.

### minEig (CPU-side, per dirty frame)

For symmetric 2x2 [[a,b],[b,c]]: mean = (a+c)/2; dev = sqrt(((a-c)/2)^2 + b^2);
minEig = mean - dev. Inverse: 1/(ac - b^2) * [[c,-b],[-b,a]].

## Attached content transform

Attached expansion uses identity for content and shader transforms throughout,
not merely at the endpoint. An old integrator matrix cannot affect its geometry.
The superseded velocity-driven travelling formulas are archived separately;
remaining motion code serves detached compatibility only, not attached reveal.

## Reveal choreography

One value per rollout: `offsetScale` (0 shown → 1 hidden), with
`p = clamp(1 - offsetScale, 0, 1)` for bounded aperture dimensions.

```qml
property real offsetScale: shouldBeActive && !suppressed ? 0 : 1
// Retain the item until the transition settles. Content rides opaque.
visible: revealAnim.running || offsetScale < 1
readonly property real revealProgress: Math.max(0, Math.min(1, 1 - offsetScale))
// The viewport extrudes from the fixed origin along one axis.
implicitWidth: revealHorizontal ? bodyWidth * revealProgress : bodyWidth
implicitHeight: revealHorizontal ? bodyHeight : bodyHeight * revealProgress
// Full-size content parks inside the growing aperture; it does not travel.
body.x: revealHorizontal && attached("right") ? width - bodyWidth : 0
body.y: !revealHorizontal && attached("bottom") ? height - bodyHeight : 0
Behavior on offsetScale { NumberAnimation { id: revealAnim
    /* Motion.revealLarge / revealSmall and revealCurve / retractCurve */ } }
```

At right, `root.x = wallX - width`, so the full body host x is
`wallX - width + width - bodyWidth = wallX - bodyWidth`. At bottom the same
algebra gives `wallY - bodyHeight`; left/top park directly on their source wall.
Only the aperture changes with reveal. Its source wall and free-axis placement
stay fixed unless the host explicitly changes source placement or target size.
Free radii clamp against current aperture half extents; content remains full-size.

Normal source depth comes from the host's left band or other band depth, with
Style fallback and explicit inset overrides. A nested source uses the parent's
settled full-body edge in host coordinates, not its animated aperture. It need
not be a QML child under the parent's clip.

Size changes have one animation owner. `Rollout.animateBodySize` defaults to
true for content that supplies a target size; a body already following animated
child extents sets it false. In that case body dimensions, clip and registry use
those extents directly, with no second morph that lets content outrun its rim.
This does not change `offsetScale` reveal/retract or any shader formula.

At hidden progress the aperture has zero depth at the source wall; stationary
full-size content is clipped out. Outness is zero and deformation identity before
slot removal. No parking travel, later border restoration or visibility timer is
introduced. Detached fullscreen placement remains outside this attached contract.

## Motion token

Large reveals use 500ms, small reveals and size morphs use 250ms. Reveal
control points are `(0.05, 0.7)`, `(0.1, 1.0)`; retract uses `(0.3, 0.0)`,
`(0.2, 1.0)`. Both end at `(1, 1)` without overshoot. Attached reveal changes
aperture depth only; no deformation or bouncing content settle is added.

## Registries

The scene window owns two registries keyed by rollout id, reassigned-not-mutated so bindings
fire: silhouette rects (shader uniforms, 8 slots) and hit rects (input mask Region slots, 8).
Both derive from reveal progress: the producer paint contour and exposed viewport
are the aperture before paint normalization. Shader welds/snapping may extend
paint, never input. Input registration is near-settled and withdraws on semantic
close/suppression, while the outgoing picture remains until hidden. Full-size
clipped content must never expand input over the application. The input mask ADDITIONALLY
always contains the host's standing regions: the band strip it reserves on the attached side
(`leftEdge` or `edge` thick, wider while the host shows or peeks content in it) and any handle
hover-zones. These are not registry slots.
