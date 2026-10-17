#version 440

// A Card's edge glow: the silhouette's grain (docs/12-mechanism.md "Edge
// glow", same hash, same step form) painted inside one rounded box. The Card's
// Rectangle keeps its fill; this pass only lays the tint over it, as
// premultiplied colour with alpha = the glow weight, so a card with the glow
// off renders exactly as before and the fill is never drawn twice.
//
// Uniforms are named, no arrays (12-mechanism uniform-packing law).
// Coordinates are LOGICAL pixels; the grain is per DEVICE pixel.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 cardSize;      // card size in logical px
    float cornerRadius; // card corner radius
    vec4 tint;      // rgb = glow tint, a = strength at the edge
    float glowWidth; // glow width in px: the tint is gone this far in (not `width`: that is the Item's)
};

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float r) {
    vec2 q = abs(p - center) - halfSize + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Float-only Hoskins hash12, identical to edgemelt.frag's grainAt.
float grainAt(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

void main() {
    vec2 halfSize = cardSize * 0.5;
    vec2 pixel = qt_TexCoord0 * cardSize;
    float sd = sdRoundedBox(pixel, halfSize, halfSize, min(cornerRadius, min(halfSize.x, halfSize.y)));

    // Coverage of the rounded box, so the tint follows the Rectangle's
    // antialiased edge and never spills past its corners.
    float fw = fwidth(sd);
    float coverage = 1.0 - smoothstep(-fw, fw, sd);

    float depth = -sd;
    float glow = 1.0 - smoothstep(0.0, glowWidth, depth);
    float n = grainAt(floor(gl_FragCoord.xy));
    float m = clamp(glow * tint.a * step(n, glow), 0.0, 1.0) * coverage;

    fragColor = vec4(tint.rgb * m, m) * qt_Opacity;
}
