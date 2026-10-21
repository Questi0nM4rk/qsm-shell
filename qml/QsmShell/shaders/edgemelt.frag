#version 440

// docs/12-mechanism.md is normative. One pass fills the merged silhouette
// and paints its edge separation (a slight line of tint at the edge fading
// inward), derivative-AA'd in logical coordinates.
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
    vec4 fillColor;
    // The handle is NOT a slot (12-mechanism): a dedicated circle SDF folded
    // with the same smin. (cx, cy, radius, blend) — radius 0 = absent.
    vec4 handle0;          // the OSD circle handle
    // Per slot: rect = (centerX, centerY, halfW, halfH) — the UNDEFORMED
    // live item rect. radii = per-corner (see sdRoundedBox4). deform = the
    // CPU-precomputed inverse 2x2 of the goo deform matrix, row-major
    // (identity = 1,0,0,1). param.x = minEig of the deform (identity = 1);
// param.y = blend factor [0,1] scaling smoothFactor for this slot's melt;
// param.z = seam side mask (CPU only) + 16 * origin side mask (read here).
// param.w = outness [0,1], how far this body has emerged (a flush nested
// host is fully OUT at blend 0, so the edge gate reads this, not blend).
    vec4 rect0; vec4 rect1; vec4 rect2; vec4 rect3;
    vec4 rect4; vec4 rect5; vec4 rect6; vec4 rect7;
    vec4 radii0; vec4 radii1; vec4 radii2; vec4 radii3;
    vec4 radii4; vec4 radii5; vec4 radii6; vec4 radii7;
    vec4 deform0; vec4 deform1; vec4 deform2; vec4 deform3;
    vec4 deform4; vec4 deform5; vec4 deform6; vec4 deform7;
    vec4 param0; vec4 param1; vec4 param2; vec4 param3;
    vec4 param4; vec4 param5; vec4 param6; vec4 param7;
    // EDGE SEPARATION: a slight line of edge colour
    // exactly at the merged silhouette's edge, fading smoothly inward into
    // the fill. Measured on the same union, so it follows every corner
    // radius and melt neck with one profile.
    vec4 edgeColor;        // rgb = edge colour, a = line strength at the edge
    float edgeFade;        // fade width in px: the colour is gone this far in
    int fullscreenMode;    // native fullscreen: detached capsules only
    int capsuleOccupied;
    vec4 capsule0; vec4 capsule1; vec4 capsule2; vec4 capsule3;
    vec4 capsule4; vec4 capsule5; vec4 capsule6; vec4 capsule7;
    float capsuleRadius0; float capsuleRadius1; float capsuleRadius2; float capsuleRadius3;
    float capsuleRadius4; float capsuleRadius5; float capsuleRadius6; float capsuleRadius7;
};

// --- SDF primitives (12-mechanism, verbatim) -------------------------------

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float r) {
    vec2 q = abs(p - center) - halfSize + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Per-corner radii: quadrant-select the active corner's radius, then the
// standard formula. Slot mapping in THIS y-down pixel space: r.x lands on
// the bottom-right corner, r.y top-right, r.z bottom-left, r.w top-left —
// ShellBorder packs radii to match (see its radiiToShaderOrder).
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

    // Band bounds: the band is everything OUTSIDE the viewport box. It has
    // no outer boundary — the screen edge is not a silhouette edge, and a
    // field that measured it cut the edge profile short at every open
    // rollout corner (12-mechanism "Band (frame) shape").
    vec2 innerHalf = vec2(resolution.x - leftEdge - edge, resolution.y - edge * 2.0) * 0.5;
    vec2 innerCenter = vec2(leftEdge, edge) + innerHalf;

    // Band (frame) shape. (No border sink: rollouts live UNDER the band —
    // the merged fill erases the wall behind a bulge natively, and a sink
    // would carve pockets around every tail.)
    float dInner = sdRoundedBox(pixel, innerCenter, innerHalf, viewportRadius);
    float minThickness = min(leftEdge, edge);
    // Edge gate, folded per slot below: 1 where every nearby body is fully
    // out, → 0 where a body is still emerging. seamReach is how far from a
    // body's own boundary the gate reaches.
    float edgeGate = 1.0;
    const float seamReach = 6.0;

    float dFrame = -dInner;

    // Rollouts: evaluate each rect's SDF in its undeformed frame by
    // inverse-transforming the sample point; the min-eigenvalue factor
    // corrects the distance metric under non-uniform scale. Fold each slot
    // into the frame iteratively — that IS the normative composition. The
    // blend radius is PER SLOT (param.y in [0,1], scaling smoothFactor):
    // a rollout's melt neck shrinks with its protrusion, so a body absorbed
    // behind its band stops bridging (and lighting the edge) exactly when it
    // disappears — the shader never sees things hidden behind the border.
    float mergedSdf = fullscreenMode != 0 ? 100000.0 : dFrame;
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
        // Blend 0 means an EXACT union, and that has to be a real min().
        //
        // The k floor was believed to deliver one ("k = max(.., 0.01) turns
        // blend 0 into a hard min") and it does not: this smin does
        // NOT converge to min as k falls. For equal inputs it reduces to
        //
        //     smin(a, a, k) = sqrt(2) * a + k * (1 - sqrt(2))
        //
        // so at a == b it inflates the INTERIOR distance by 41% however small k
        // is. That is invisible to `alpha`, which only cares about the zero
        // crossing (at a == b == 0 the deviation is just -0.414 * k), but the
        // edge reads depth from `-mergedSdf`, so along a flush seam -- where
        // the two fields are EQUAL, the worst case -- it would believe it was
        // 1.4x deeper inside and fade early. The edge divides by the field's
        // gradient length below, which removes that inflation.
        float blendAmount = clamp(param.y, 0.0, 1.0);
        float slotSdf = blendAmount > 0.0
            ? smin(incomingSdf, d, smoothFactor * blendAmount)
            : min(incomingSdf, d);

        // WATER LAW: a body that has not come out yet has
        // no edge of its own. A barely-out rollout drives its melt radius
        // toward zero, smin degenerates to a hard min, and the union keeps a
        // full boundary where the new body meets whatever it is emerging
        // from — which the edge then draws as a line. Worst on a
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
        edgeGate = min(edgeGate, mix(1.0, outness, newBoundary));

        // Only origin sides extend fill. A parent's child-facing continuation
        // is seam paint, otherwise it would outrun a child still emerging.
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
        // Restore the whole incoming field, including edge depth and normals,
        // before removal; matching only its zero contour leaves a lighting snap.
        mergedSdf = mix(incomingSdf, slotSdf, outness);
    }

    // Handle circles (dedicated uniforms, not slots). They belong only to the
    // attached path; fullscreen has no persistent affordances.
    if (fullscreenMode == 0 && handle0.z > 0.0) {
        float dHandle = length(pixel - handle0.xy) - handle0.z;
        mergedSdf = smin(mergedSdf, dHandle,
            max(smoothFactor * clamp(handle0.w, 0.0, 1.0), 0.01));
    }

    // Derivative AA: equal edge weight on every axis and monitor scale.
    float fw = fwidth(mergedSdf);
    float alpha = 1.0 - smoothstep(-fw, fw, mergedSdf);

    // Edge separation (12-mechanism "Edge separation"): a slight line of the
    // edge colour exactly at the union's edge, fading smoothly inward to the
    // fill over edgeFade px. One curve of one distance, so every bulge, join
    // and corner gets the same edge. Kept INSIDE the shape: paint, not
    // geometry, so alpha and the input mask are untouched.
    //
    // mergedSdf is a true distance only near a single wall (smin inflates it
    // where two fields overlap and deflates it between facing walls), so
    // divide by its own gradient length: the first-order distance estimate.
    // dFdx(pixel) is logical px per device px, which makes gradLen
    // scale-free; the clamp keeps a flat spot (a neck's midline) finite.
    float gradLen = length(vec2(dFdx(mergedSdf), dFdy(mergedSdf)))
        / length(dFdx(pixel));
    float dist = max(-mergedSdf, 0.0) / clamp(gradLen, 0.5, 2.0);
    float s = clamp(dist / edgeFade, 0.0, 1.0);
    float w = edgeColor.a * (1.0 - s) * (1.0 - s) * edgeGate;
    vec3 rgb = mix(fillColor.rgb, edgeColor.rgb, clamp(w, 0.0, 1.0));

    fragColor = vec4(rgb * alpha, alpha) * qt_Opacity;
}
