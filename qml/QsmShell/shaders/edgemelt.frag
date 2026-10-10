#version 440

// docs/12-mechanism.md is normative. One pass fills the merged silhouette
// and paints its inner glass edge, derivative-AA'd in logical coordinates.
//
// Uniform shape is NAMED per-slot (rect0..7 / radii0..7 / deform0..7 /
// param0..7), not a GLSL array: QML array properties bind to GLSL array
// uniforms as silent zeros on this Qt 6.11 / Quickshell 0.3 stack
// (12-mechanism uniform-packing law; re-probe on Qt upgrades).
//
// Coordinates are LOGICAL pixels; fractional monitor scale is absorbed by
// the fwidth-based AA, never by hand-scaling constants.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    float leftEdge;        // band thickness left (60 revealed, 16 collapsed)
    float edge;            // band thickness top/right/bottom (16)
    float viewportRadius;  // viewport corner rounding (25)
    float smoothFactor;    // melt reach (20) — every join neck derives from it
    int occupied;          // occupied slot count (registry packs from 0)
    float rimWidth;        // edge-readability rim ramp width (01-frame)
    vec4 fillColor;
    vec4 rimColor;         // rgb = rim tint, a = strength
    // Handles are NOT slots (12-mechanism): dedicated circle SDFs folded
    // with the same smin. (cx, cy, radius, blend) — radius 0 = absent.
    vec4 handle0;          // the OSD circle handle
    vec4 dotsHandle;       // top-panel dots: (centerX, firstRowCy, r, spacing)
    // Per slot: rect = (centerX, centerY, halfW, halfH) — the UNDEFORMED
    // live item rect. radii = per-corner (see sdRoundedBox4). deform = the
    // CPU-precomputed inverse 2x2 of the goo deform matrix, row-major
    // (identity = 1,0,0,1). param.x = minEig of the deform (identity = 1);
// param.y = blend factor [0,1] scaling smoothFactor for this slot's melt;
// param.z = rim side mask + 16 * origin side mask.
// param.w = outness [0,1], how far this body has emerged (a flush nested
// host is fully OUT at blend 0, so the glass edge reads this, not blend).
    vec4 rect0; vec4 rect1; vec4 rect2; vec4 rect3;
    vec4 rect4; vec4 rect5; vec4 rect6; vec4 rect7;
    vec4 radii0; vec4 radii1; vec4 radii2; vec4 radii3;
    vec4 radii4; vec4 radii5; vec4 radii6; vec4 radii7;
    vec4 deform0; vec4 deform1; vec4 deform2; vec4 deform3;
    vec4 deform4; vec4 deform5; vec4 deform6; vec4 deform7;
    vec4 param0; vec4 param1; vec4 param2; vec4 param3;
    vec4 param4; vec4 param5; vec4 param6; vec4 param7;
    // GLASS EDGE (owner 2026-08-19): a crisp light line hugging the INSIDE of
    // the merged silhouette, drawn ON TOP of the flat fill. Not the old rim:
    // that was a wide gradient ramp inside the body, which lit the melt necks
    // unevenly and read as a different material. This is one stroke of the
    // same union, so it follows every corner radius and every melt neck for
    // free — the shape stops bleeding into the wallpaper and gains an edge.
    vec4 strokeColor;      // rgb = glass tint, a = strength
    float strokeWidth;     // inner stroke thickness in px
    int fullscreenMode;    // native fullscreen: detached capsules only
    int capsuleOccupied;
    vec4 capsule0; vec4 capsule1; vec4 capsule2; vec4 capsule3;
    vec4 capsule4; vec4 capsule5; vec4 capsule6; vec4 capsule7;
    float capsuleRadius0; float capsuleRadius1; float capsuleRadius2; float capsuleRadius3;
    float capsuleRadius4; float capsuleRadius5; float capsuleRadius6; float capsuleRadius7;
};

// --- SDF primitives (12-mechanism, verbatim) -------------------------------

float sdBox(vec2 p, vec2 center, vec2 halfSize) {
    vec2 q = abs(p - center) - halfSize;
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float r) {
    vec2 q = abs(p - center) - halfSize + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Per-corner radii: quadrant-select the active corner's radius, then the
// standard formula. Slot mapping in THIS y-down pixel space: r.x lands on
// the bottom-right corner, r.y top-right, r.z bottom-left, r.w top-left —
// EdgeScene packs radii to match (see its radiiToShaderOrder).
float sdRoundedBox4(vec2 p, vec2 center, vec2 halfSize, vec4 r) {
    vec2 d = p - center;
    r.xy = (d.x > 0.0) ? r.xy : r.zw;
    r.x  = (d.y > 0.0) ? r.x  : r.y;
    vec2 q = abs(d) - halfSize + vec2(r.x);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r.x;
}

// --- Blend family (circular — arc fillets, radius k) -----------------------
// Deviates from min(a,b) only where BOTH inputs are < k; max blend depth at
// a==b is (sqrt(2)-1)*k.

float smin(float a, float b, float k) {
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}

// smaxSharpA keeps operand a's zero-boundary sharp — used only for the
// band's outer (screen) edge so it stays flush to the last pixel row.
float smaxSharpA(float a, float b, float k) {
    float sm = min(-k, max(a, b)) + length(max(vec2(a, b) + vec2(k), vec2(0.0)));
    float blend = (sm - max(a, b)) * smoothstep(0.0, k * 0.5, -a);
    return max(a, b) + blend;
}

// --- Named-slot lookup ------------------------------------------------------

void slotAt(int i, out vec4 rect, out vec4 radii, out vec4 deform, out vec4 param) {
    if (i == 0) { rect = rect0; radii = radii0; deform = deform0; param = param0; }
    else if (i == 1) { rect = rect1; radii = radii1; deform = deform1; param = param1; }
    else if (i == 2) { rect = rect2; radii = radii2; deform = deform2; param = param2; }
    else if (i == 3) { rect = rect3; radii = radii3; deform = deform3; param = param3; }
    else if (i == 4) { rect = rect4; radii = radii4; deform = deform4; param = param4; }
    else if (i == 5) { rect = rect5; radii = radii5; deform = deform5; param = param5; }
    else if (i == 6) { rect = rect6; radii = radii6; deform = deform6; param = param6; }
    else { rect = rect7; radii = radii7; deform = deform7; param = param7; }
}

void capsuleAt(int i, out vec4 rect, out float radius) {
    if (i == 0) { rect = capsule0; radius = capsuleRadius0; }
    else if (i == 1) { rect = capsule1; radius = capsuleRadius1; }
    else if (i == 2) { rect = capsule2; radius = capsuleRadius2; }
    else if (i == 3) { rect = capsule3; radius = capsuleRadius3; }
    else if (i == 4) { rect = capsule4; radius = capsuleRadius4; }
    else if (i == 5) { rect = capsule5; radius = capsuleRadius5; }
    else if (i == 6) { rect = capsule6; radius = capsuleRadius6; }
    else { rect = capsule7; radius = capsuleRadius7; }
}

void main() {
    vec2 pixel = qt_TexCoord0 * resolution;

    // Band bounds. Outer box = the whole scene; inner box = the viewport.
    vec2 outerHalf = resolution * 0.5;
    vec2 outerCenter = outerHalf;
    vec2 innerHalf = vec2(resolution.x - leftEdge - edge, resolution.y - edge * 2.0) * 0.5;
    vec2 innerCenter = vec2(leftEdge, edge) + innerHalf;

    // Band (frame) shape. -1 on dOuter: cover the last pixel row. The inner
    // corner fillet must not exceed the thinnest band side. (No border sink:
    // rollouts live UNDER the band — the merged fill erases the wall behind
    // a bulge natively, and a sink would carve pockets around every tail.)
    float dOuter = sdBox(pixel, outerCenter, outerHalf) - 1.0;
    float dInner = sdRoundedBox(pixel, innerCenter, innerHalf, viewportRadius);
    float minThickness = min(leftEdge, edge);
    float kFrame = clamp(min(smoothFactor, minThickness - 1.0), 1.0, smoothFactor);
    // Glass-edge gate, folded per slot below: 1 where every nearby body is
    // fully out, → 0 where a body is still emerging. seamReach is how far
    // from a body's own boundary the gate reaches.
    float strokeGate = 1.0;
    const float seamReach = 6.0;

    float dFrame = smaxSharpA(dOuter, -dInner, kFrame);

    // Rollouts: evaluate each rect's SDF in its undeformed frame by
    // inverse-transforming the sample point; the min-eigenvalue factor
    // corrects the distance metric under non-uniform scale. Fold each slot
    // into the frame iteratively — that IS the normative composition. The
    // blend radius is PER SLOT (param.y in [0,1], scaling smoothFactor):
    // a rollout's melt neck shrinks with its protrusion, so a body absorbed
    // behind its band stops bridging (and lighting the rim) exactly when it
    // disappears — the shader never sees things hidden behind the border.
    // rimSdf runs alongside with a HARD min: the circular smin deepens the
    // interior wherever two near-equal fields overlap (a rollout's tail over
    // the band), which read as dead rim patches — the rim wants the exact
    // union distance, the fill wants the melted one.
    float mergedSdf = fullscreenMode != 0 ? 100000.0 : dFrame;
    float rimSdf = fullscreenMode != 0 ? 100000.0 : dFrame;
    if (fullscreenMode != 0) {
        for (int i = 0; i < 8; i++) {
            if (i >= capsuleOccupied)
                break;
            vec4 capsule;
            float radius;
            capsuleAt(i, capsule, radius);
            vec2 halfSize = capsule.zw;
            if (halfSize.x <= 0.0 || halfSize.y <= 0.0)
                continue;
            float d = sdRoundedBox(pixel, capsule.xy, halfSize, min(radius, min(halfSize.x, halfSize.y)));
            mergedSdf = min(mergedSdf, d);
        }
    }
    for (int i = 0; i < 8; i++) {
        if (fullscreenMode != 0)
            break;
        if (i >= occupied)
            break;
        vec4 rect, radii, invDm, param;
        slotAt(i, rect, radii, invDm, param);
        float outness = clamp(param.w, 0.0, 1.0);
        if (outness <= 0.0)
            continue;
        vec2 center = rect.xy;
        vec2 halfSize = rect.zw;
        if (halfSize.x <= 0.0 || halfSize.y <= 0.0)
            continue;
        mat2 invDeform = mat2(invDm.xy, invDm.zw);
        vec2 tp = center + invDeform * (pixel - center);
        float d = sdRoundedBox4(tp, center, halfSize, radii);
        d *= max(param.x, 0.01);
        float incomingSdf = mergedSdf;
        float incomingRimSdf = rimSdf;
        // Blend 0 means an EXACT union, and that has to be a real min().
        //
        // The k floor was believed to deliver one ("k = max(.., 0.01) turns
        // blend 0 into a hard min", spec/03) and it does not: this smin does
        // NOT converge to min as k falls. For equal inputs it reduces to
        //
        //     smin(a, a, k) = sqrt(2) * a + k * (1 - sqrt(2))
        //
        // so at a == b it inflates the INTERIOR distance by 41% however small k
        // is. That is invisible to `alpha`, which only cares about the zero
        // crossing (at a == b == 0 the deviation is just -0.414 * k), but the
        // glass stroke measures `innerDepth = -mergedSdf` against strokeWidth,
        // so along a flush seam -- where the two fields are EQUAL, the worst
        // case -- it believed it was 1.4x deeper inside and stopped drawing.
        // Measured 2026-08-25: the edge kept its outer row and lost its inner
        // one across exactly the overlap span, which the owner read as "a dent
        // in the glass edge, from the inside only, not going outwards".
        float blendAmount = clamp(param.y, 0.0, 1.0);
        float slotSdf = blendAmount > 0.0
            ? smin(incomingSdf, d, smoothFactor * blendAmount)
            : min(incomingSdf, d);

        // WATER LAW (owner 2026-09-06): a body that has not come out yet has
        // no edge of its own. A barely-out rollout drives its melt radius
        // toward zero, smin degenerates to a hard min, and the union keeps a
        // full boundary where the new body meets whatever it is emerging
        // from — which the glass stroke then draws as a hard line. Worst on a
        // second-level rollout, where the line flashes BETWEEN the two bodies
        // for the length of the reveal.
        //
        // The gate is param.w (outness), NOT param.y (blend). They are the
        // same number for a plain Rollout and deliberately different for a
        // flush nested host, which sets blend 0 to ask for an exact union
        // while being fully out. Gating on blend blanked that host's edge
        // entirely (owner-caught within the hour).
        float nearThis = 1.0 - smoothstep(0.0, seamReach, abs(d));
        // The existing union's edge must never blink while a body is absorbed.
        float newBoundary = nearThis * smoothstep(0.0, seamReach, incomingSdf);
        strokeGate = min(strokeGate, mix(1.0, outness, newBoundary));

        // Only origin sides extend fill. A parent's child-facing continuation
        // is rim paint, otherwise it would outrun a child still emerging.
        float originBits = floor(param.z / 16.0);
        float ext = max(leftEdge, edge) + smoothFactor;
        vec2 weldCenter = center;
        vec2 weldHalf = halfSize;
        if (mod(originBits, 2.0) >= 1.0) { weldCenter.x -= ext * 0.5; weldHalf.x += ext * 0.5; }
        if (mod(originBits, 4.0) >= 2.0) { weldCenter.x += ext * 0.5; weldHalf.x += ext * 0.5; }
        if (mod(originBits, 8.0) >= 4.0) { weldCenter.y -= ext * 0.5; weldHalf.y += ext * 0.5; }
        if (originBits >= 8.0) { weldCenter.y += ext * 0.5; weldHalf.y += ext * 0.5; }
        float dWeld = sdRoundedBox4(tp, weldCenter, weldHalf, radii) * max(param.x, 0.01);
        // A flush child keeps an exact parent seam, but still melts into the
        // original frame. Smoothing against the accumulated union would bulge
        // the parent/child seam again.
        float frameJoin = min(smoothFactor, minThickness * 0.5) * outness;
        float attachedBody = blendAmount == 0.0
            ? (frameJoin > 0.0 ? smin(dFrame, dWeld, frameJoin) : min(dFrame, dWeld))
            : dWeld;
        slotSdf = min(slotSdf, attachedBody);
        // Restore the whole incoming field, including stroke depth and normals,
        // before removal; matching only its zero contour leaves a lighting snap.
        mergedSdf = mix(incomingSdf, slotSdf, outness);

        float bits = mod(param.z, 16.0);
        vec2 rimCenter = center;
        vec2 rimHalf = halfSize;
        if (mod(bits, 2.0) >= 1.0) { rimCenter.x -= ext * 0.5; rimHalf.x += ext * 0.5; }
        if (mod(bits, 4.0) >= 2.0) { rimCenter.x += ext * 0.5; rimHalf.x += ext * 0.5; }
        if (mod(bits, 8.0) >= 4.0) { rimCenter.y -= ext * 0.5; rimHalf.y += ext * 0.5; }
        if (bits >= 8.0) { rimCenter.y += ext * 0.5; rimHalf.y += ext * 0.5; }
        float dRim = sdRoundedBox4(tp, rimCenter, rimHalf, radii) * max(param.x, 0.01);
        rimSdf = mix(incomingRimSdf, min(incomingRimSdf, dRim), outness);
    }

    // Handle circles (dedicated uniforms, not slots). They belong only to the
    // attached desktop path; fullscreen has no persistent affordances.
    if (fullscreenMode == 0 && handle0.z > 0.0) {
        float dHandle = length(pixel - handle0.xy) - handle0.z;
        mergedSdf = smin(mergedSdf, dHandle,
            max(smoothFactor * clamp(handle0.w, 0.0, 1.0), 0.01));
        rimSdf = min(rimSdf, dHandle);
    }
    // Top-panel dot handle: 8 dots, two rows of 4 around centerX, melted
    // gently (k=8) so they read as dots, not one blob.
    if (fullscreenMode == 0 && dotsHandle.z > 0.0) {
        for (int r = 0; r < 2; r++) {
            for (int c = 0; c < 4; c++) {
                vec2 dotPos = vec2(dotsHandle.x + (float(c) - 1.5) * dotsHandle.w,
                                   dotsHandle.y + float(r) * dotsHandle.w);
                float dDot = length(pixel - dotPos) - dotsHandle.z;
                mergedSdf = smin(mergedSdf, dDot, 8.0);
                rimSdf = min(rimSdf, dDot);
            }
        }
    }

    // Derivative AA: equal edge weight on every axis and monitor scale.
    float fw = fwidth(mergedSdf);
    float alpha = 1.0 - smoothstep(-fw, fw, mergedSdf);

    // Edge-readability rim (01-frame, formula amended 2026-08-17): the fill
    // ramps toward rimColor as the sample nears the union's edge — but ONLY
    // where the nearest edge is an INNER one. A pixel closer to the outer
    // screen edge than to any inner boundary gets NO rim (a plain fade mask
    // left a light ring around the whole screen; owner-caught twice).
    // The rim field is max(melted, exact-union): exact alone leaves the melt
    // neck dark (its visible edge only exists in the melted field — read as
    // a barrier gutter between a rollout's lit corners and the band;
    // owner-caught), melted alone kills the rim in absorbed-tail overlaps
    // (smin deepens near-equal interiors). max keeps the shallower field.
    float innerDist = -max(mergedSdf, rimSdf);
    float outerDist = -dOuter;
    float rim = (fullscreenMode != 0 ? 0.0 : (1.0 - smoothstep(0.0, rimWidth, innerDist)))
        * smoothstep(0.0, 2.0, outerDist - innerDist);
    vec3 rgb = mix(fillColor.rgb, rimColor.rgb, rim * rimColor.a);

    // Inner stroke: distance from the union's boundary, measured inward. 1 at
    // the boundary, 0 once deeper than strokeWidth. Kept INSIDE the shape so
    // the silhouette's alpha (and therefore its input mask) is untouched — the
    // line is paint, not geometry.
    // Solid across its whole width, with AA on the INNER side only: ramping
    // over +/-fw made a 1.5px line entirely gradient, which read as a fade
    // toward the middle rather than as an edge (owner 2026-08-19).
    float innerDepth = -mergedSdf;
    float stroke = (1.0 - smoothstep(strokeWidth - fw, strokeWidth, innerDepth))
        * step(0.0, innerDepth)
        // INNER edges only. mergedSdf measures distance to ANY boundary, so
        // without this the line also traces the outer screen edge and the band
        // reads as double-lined (owner 2026-08-19). Same gate the rim uses: a
        // pixel nearer the outer edge than to any inner boundary gets none.
        * (fullscreenMode != 0 ? 1.0 : smoothstep(0.0, 2.0, outerDist - innerDepth));

    // Glassy, not uniform: the light sits at the CENTRE OF THE SCREEN and
    // radiates outward (owner 2026-09-06), replacing a fixed overhead light.
    // Overhead was wrong for this shape: the band wraps all four screen
    // edges, so one global up-vector lit the top band and starved the bottom
    // one no matter what the surface was doing. A centre light is symmetric
    // about the thing the band actually surrounds, so every edge is lit by
    // how much it FACES INWARD, which is the same everywhere on the ring.
    // The SDF gradient is the surface normal pointing out of the shape;
    // dotting it with the direction to the centre is the lit amount.
    // dFdy is measured NEGATIVE against the pixel y axis on this stack: the
    // RHI framebuffer is y-flipped relative to qt_TexCoord0, so the raw
    // derivative pair is not the outward normal — its y is inverted. With the
    // overhead light this only decided which band looked lit and was tuned by
    // eye; with a centre light it cancelled the y term outright and the top
    // and bottom bands lost their edge completely (owner 2026-09-06).
    vec2 edgeNormal = vec2(dFdx(mergedSdf), -dFdy(mergedSdf));
    vec2 toLight = (resolution * 0.5) - pixel;
    float facing = (length(edgeNormal) > 0.0001 && length(toLight) > 0.0001)
        ? dot(normalize(edgeNormal), normalize(toLight))
        : 0.0;
    // A point light has a distance term, and without one every edge on the
    // screen was equally lit no matter how far in it reached — a rollout that
    // pushes deep toward the light read no brighter than the band it came out
    // of (owner 2026-09-06). Proximity BOOSTS rather than dims: the band sits
    // at strokeColor.a as before and nearer edges climb above it, so nothing
    // that already looked right got darker.
    float prox = 1.0 - clamp(length(toLight) / (0.5 * length(resolution)), 0.0, 1.0);
    float glass = mix(0.3, 1.0, clamp(facing * 0.5 + 0.5, 0.0, 1.0))
        * mix(1.0, 1.7, prox);

    rgb = mix(rgb, strokeColor.rgb,
        clamp(stroke * strokeColor.a * glass * strokeGate, 0.0, 1.0));

    fragColor = vec4(rgb * alpha, alpha) * qt_Opacity;
}
