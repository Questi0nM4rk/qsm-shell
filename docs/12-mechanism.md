# 12 — Mechanism (normative reference code)

The implementation vocabulary the spec assumes. Code below is NORMATIVE: implementers use
these exact formulas/patterns; deviations require editing this file first.

## Silhouette shader

One full-screen ShaderEffect per monitor computes the whole silhouette (band + all rollouts)
per pixel and fills it. Single pass; no per-shape draw calls.

The fill carries ONE line of paint: the glass edge, a lit stroke hugging the INSIDE of the
merged silhouette (see "Glass edge" below). It is not a border and not a stroke around a
shape — 01-frame still forbids those, and nothing draws its own chrome. It is the union's own
edge, painted, and it exists only on inner boundaries.

### SDF primitives

```glsl
float sdBox(vec2 p, vec2 center, vec2 halfSize) {
    vec2 q = abs(p - center) - halfSize;
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

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
`(sqrt(2)-1)*k`. `smaxSharpA` keeps operand `a`'s zero-boundary sharp — used only for the
band's outer (screen) edge so it stays flush to the last pixel row.

```glsl
float smin(float a, float b, float k) {
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}
float smax(float a, float b, float k) {
    return min(-k, max(a, b)) + length(max(vec2(a, b) + vec2(k), vec2(0.0)));
}
float smaxSharpA(float a, float b, float k) {
    float sm = min(-k, max(a, b)) + length(max(vec2(a, b) + vec2(k), vec2(0.0)));
    float blend = (sm - max(a, b)) * smoothstep(0.0, k * 0.5, -a);
    return max(a, b) + blend;
}
```

### Band (frame) shape

```glsl
float dOuter = sdBox(pixel, outerCenter, outerHalf) - 1.0;   // -1: cover the last pixel row
float dInner = sdRoundedBox(pixel, innerCenter, innerHalf, viewportRounding);
// inner corner fillet must not exceed the thinnest band side:
float kFrame = clamp(min(smoothFactor, minThickness - 1.0), 1.0, smoothFactor);
float dFrame = smaxSharpA(dOuter, -dInner, kFrame);
```

### Border sink — ABOLISHED (owner, 2026-08-17)

The sink (wall receding toward a penetrating rect) belonged to the era when rollouts
approached the band from the viewport side. Under the border-origin travel law
(02-rollouts) every rollout keeps a tail permanently under its band, which saturated the
sink and carved visible pockets around every bulge and parked rollout. The merged fill
erases the wall behind a bulge natively — `dInner` is used unmodified.

### Composition and fill

```glsl
// mergedSdf: start from dFrame and fold every occupied slot iteratively —
// result = smin(result, d_i, smoothFactor * param_i.y) — the per-slot blend
// factor (2026-08-17) shrinks a rollout's neck with its protrusion so a body
// absorbed behind its band stops bridging exactly when it disappears.
float fw = fwidth(mergedSdf);                       // derivative AA: equal weight every axis
float alpha = 1.0 - smoothstep(-fw, fw, mergedSdf);
fragColor = vec4(fillColor.rgb * alpha, alpha) * qt_Opacity;
```

Constants (ratified in 01-frame): band left 60 / others 16, smoothFactor 20, rollout radius 28
(per-corner: 0 on the DECLARED attached edge(s) only — corner auto-join to a second nearby
band segment is the smin's job, not a radius zeroing), viewport rounding 25. All shader
coordinates are LOGICAL pixels; fractional monitor scale is absorbed by fwidth-based AA.

### Deformed evaluation (squash/stretch, see Physics)

The shader evaluates each rect's SDF in the rect's undeformed frame by inverse-transforming
the sample point; a min-eigenvalue factor corrects the distance metric under non-uniform
scale:

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
y = melt-blend factor [0,1], z = edge bits, w = outness [0,1]).
Empty slot = zero rect (contributes nothing), and its param is `(1, 1, 0, 1)`.

`z` is a bitmask of the bands this rect is welded through — 1 left, 2 right, 4 top, 8 bottom
— used to extend the RIM copy of the rect through them so no readability line is drawn at the
seam where a rollout meets its border.

`w` is OUTNESS: how far this body has emerged, 0 hidden to 1 fully out. It is a different
fact from `y` and the two must not be conflated. `y` is the melt radius, and a caller may set
it to exactly 0 to ask for an EXACT union with a straight seam — a nested host flush against
its parent does this deliberately, while being fully out. Only `w` may gate the glass edge.
Handles are NOT slots: the OSD circle handle and the top dot handles are dedicated uniforms
rendered with a circle SDF — `length(p - c) - r` — folded into mergedSdf with the same smin.
Slot budget (worst concurrent case): rail popout + OSD + notification rollout + one global
modal + calendar = 5 of 8; peek is the band itself (no slot). Never exceeds 8.

### Glass edge

A solid line of `strokeColor` hugging the inside of the merged silhouette, `strokeWidth` deep,
AA'd on the INNER side only (ramping both sides makes a 1.5px line entirely gradient, which
reads as a fade toward the middle rather than as an edge).

```glsl
float innerDepth = -mergedSdf;
float stroke = (1.0 - smoothstep(strokeWidth - fw, strokeWidth, innerDepth))
    * step(0.0, innerDepth)
    * smoothstep(0.0, 2.0, outerDist - innerDepth);   // INNER boundaries only
```

The last factor is not optional: `mergedSdf` measures distance to ANY boundary, so without it
the line also traces the outer screen edge and the band reads as double-lined.

**Water law.** A body that has not come out yet has no edge of its own. A barely-out rollout
drives its melt radius toward zero, smin degenerates to a hard min, and the union keeps a full
boundary where the new body meets whatever it is emerging from — which the stroke would then
draw as a hard line between them. So the stroke is gated by OUTNESS, per slot, near that
slot's own boundary:

```glsl
const float seamReach = 6.0;
float outness = clamp(param.w, 0.0, 1.0);              // param.w, NEVER param.y
float nearThis = 1.0 - smoothstep(0.0, seamReach, abs(d));
strokeGate = min(strokeGate, mix(1.0, outness, nearThis));
```

**Light.** A point light at the CENTRE OF THE SCREEN, radiating outward. Not an overhead
vector: the band wraps all four screen edges, so one global up-vector lights the top band and
starves the bottom one regardless of what the surface is doing, and a rollout reads
differently for no reason but which edge it attached to. A centre light is symmetric about the
thing the band surrounds, so every stretch of edge is lit by how much it FACES INWARD.

```glsl
vec2 edgeNormal = vec2(dFdx(mergedSdf), -dFdy(mergedSdf));   // note the sign
vec2 toLight = (resolution * 0.5) - pixel;
float facing = dot(normalize(edgeNormal), normalize(toLight));
float prox = 1.0 - clamp(length(toLight) / (0.5 * length(resolution)), 0.0, 1.0);
float glass = mix(0.3, 1.0, clamp(facing * 0.5 + 0.5, 0.0, 1.0)) * mix(1.0, 1.7, prox);

rgb = mix(rgb, strokeColor.rgb, clamp(stroke * strokeColor.a * glass * strokeGate, 0.0, 1.0));
```

`dFdy` is NEGATED. Measured on this stack: the RHI framebuffer is y-flipped relative to
`qt_TexCoord0`, so the raw derivative pair is not the outward normal — its y is inverted.
Under an overhead light this only decided which band looked lit; under a centre light it
cancels the y term outright and both horizontal bands lose their edge. Re-probe on a Qt
upgrade.

Proximity BOOSTS rather than dims (x1 at the screen corner, x1.7 at the centre), so the band
stays at `strokeColor.a` and edges reaching further in climb above it. A point light with no
distance term at all made a rollout pushing deep toward the light read no brighter than the
band it came out of.

### minEig (CPU-side, per dirty frame)

For symmetric 2x2 [[a,b],[b,c]]: mean = (a+c)/2; dev = sqrt(((a-c)/2)^2 + b^2);
minEig = mean - dev. Inverse: 1/(ac - b^2) * [[c,-b],[-b,a]].

## Physics (squash/stretch spring)

Per rollout: a symmetric 2x2 deform matrix (dm00, dm01, dm11; rest = 1,0,1) spring-driven by
the rect's own scene-space velocity. Applied twice: as a `Matrix4x4` transform on the content
(pivot = item center) and as `invDeform`+`minEig` to the shader (above) — content and
silhouette deform together.

```text
each frame (dt outside [0.001, 0.1] -> skip the INTEGRATION step only; still resample
prevScenePos so the next frame's velocity is sane):
  vel = (scenePos - prevScenePos) / dt ; speed = |vel|   # logical px/second
  active only when speed > 5.0
  # deformScale multiplies speed in px/MILLISECOND (speed/1000) — at px/s the
  # ratified intensities (0.10..0.25) would saturate the cap instantly.
  stretch  = 1 + min((speed / 1000) * deformScale, 0.35)   # hard cap 35%
  compress = 1 / stretch
  c = velX/speed ; s = velY/speed          # no atan2 needed
  target00 = stretch*c*c + compress*s*s
  target01 = (stretch - compress)*c*s
  target11 = stretch*s*s + compress*c*c
  # implicit damping — unconditionally stable at any dt:
  invDamp = 1 / (1 + damping * dt)
  dmVel = (dmVel - stiffness * (dm - target) * dt) * invDamp
  dm   += dmVel * dt
  at rest (|dm - identity| < 0.002 and |dmVel| small and speed < 5): snap to identity
```

Defaults: stiffness 200, damping 16. Per-surface `deformScale` (intensity) — RATIFIED in
10-motion: popouts 0.10, OSD 0.25, notifications 0.15, top panel 0.10, launcher 0.10,
session 0.20.

QML port shape: three `real` properties + a `FrameAnimation`-driven sampler for scene
velocity; content transform built as translate(c) · M · translate(−c).

## Reveal choreography (ratified in 02-rollouts)

One value per rollout: `offsetScale` (0 shown → 1 hidden).

```qml
property real offsetScale: shouldBeActive ? 0 : 1
// Render until the animation SETTLES, not until the value crosses 1 — the
// overshoot curve crosses 1 mid-retract and cutting off there snaps the
// band sink back (02-rollouts no-opacity-ramp law). No opacity binding:
// content rides fully drawn and opaque.
visible: revealAnim.running || offsetScale < 1
// Back limit: position clamps at flush — overshoot past 0 detaches the
// attached edge. Border-origin travel: the rect keeps an edgeInset-deep
// tail under the band (implicit size = body + edgeInset); shown at the
// screen edge, hidden = body swallowed behind the wall; content clipped
// at the wall (02-rollouts laws, 2026-08-17).
anchors.topMargin: -(bodyHeight + smoothFactor + 5) * Math.max(0, offsetScale) // per attached edge
Behavior on offsetScale { NumberAnimation { id: revealAnim
    /* the 10-motion token: 500ms or 250ms tier, bezier 0.38,1.21,0.22,1
       via easing.bezierCurve */ } }
```

The silhouette rect the shader receives is bound 1:1 to the LIVE item rect — including its
off-screen excursion while sliding. No clamping, no synthetic rects.

## Motion token (RATIFIED — see 10-motion)

500ms, cubic-bezier control points `(0.38, 1.21)`, `(0.22, 1.0)` — first control point above
1 produces the overshoot.

## Registries

The scene window owns two registries keyed by rollout id, reassigned-not-mutated so bindings
fire: silhouette rects (shader uniforms, 8 slots) and hit rects (input mask Region slots, 8).
Both are fed by the SAME live geometry (02-rollouts input law). The input mask ADDITIONALLY
always contains: the band/rail strip (60px revealed or peeked, 16px collapsed) and the two
handle hover-zones (09-input) — these are standing regions, not registry slots.
