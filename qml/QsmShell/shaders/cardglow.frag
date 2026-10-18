#version 440

// A Card's edge separation: the silhouette's profile (docs/12-mechanism.md
// "Edge separation", same curve) painted inside one rounded box. The Card's
// Rectangle keeps its fill; this pass only lays the edge colour over it, as
// premultiplied colour with alpha = the edge weight, so a card with the edge
// off renders exactly as before and the fill is never drawn twice.
//
// A box's SDF is already a true distance, so the gradient normalisation the
// silhouette needs is not repeated here.
//
// Uniforms are named, no arrays (12-mechanism uniform-packing law).
// Coordinates are LOGICAL pixels.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 cardSize;      // card size in logical px
    float cornerRadius; // card corner radius
    vec4 tint;      // rgb = edge colour, a = line strength at the edge
    float edgeFade;  // fade width in px: the colour is gone this far in
};

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float r) {
    vec2 q = abs(p - center) - halfSize + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 halfSize = cardSize * 0.5;
    vec2 pixel = qt_TexCoord0 * cardSize;
    float sd = sdRoundedBox(pixel, halfSize, halfSize, min(cornerRadius, min(halfSize.x, halfSize.y)));

    // Coverage of the rounded box, so the edge follows the Rectangle's
    // antialiased edge and never spills past its corners.
    float fw = fwidth(sd);
    float coverage = 1.0 - smoothstep(-fw, fw, sd);

    float s = clamp(-sd / edgeFade, 0.0, 1.0);
    float m = clamp(tint.a * (1.0 - s) * (1.0 - s), 0.0, 1.0) * coverage;

    fragColor = vec4(tint.rgb * m, m) * qt_Opacity;
}
