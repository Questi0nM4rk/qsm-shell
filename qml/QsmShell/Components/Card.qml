import QtQuick
import QtQuick.Effects

import qs.QsmShell.Style

Rectangle {
    id: root

    property color surfaceColor: Style.surface
    // Translucency applies only with `shadow: false`; a card that casts its
    // shadow is opaque (the copy beneath keeps the fill from showing it).
    property real surfaceOpacity: Style.surfaceOpacity
    // The silhouette's edge separation (a slight line at the edge fading
    // inward), painted inside this card's rounded edge so the card reads as an
    // object, not a traced rectangle. A card that sits flat inside another
    // body (a callout, a button) turns it off.
    property bool glow: true
    // The slight shadow that says where the card ends: the body's step
    // separates it from the ground, the shadow only finishes the edge.
    property bool shadow: true

    color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, surfaceOpacity)
    radius: Style.radiusLg

    // Beneath the card (negative z paints under the parent's own fill): an
    // opaque copy of the body in the card's colour, so the translucent fill
    // above it changes nothing and only the shadow it casts shows past the
    // edge. This is why a shadowed card is opaque.
    Rectangle {
        anchors.fill: parent
        z: -1
        visible: root.shadow && root.color.a > 0
        radius: root.radius
        color: root.surfaceColor
        layer.enabled: visible && !Style.reducedEffects
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Style.shadow
            shadowOpacity: Style.cardShadowOpacity
            shadowBlur: Style.cardShadowBlur
            shadowVerticalOffset: Style.cardShadowOffset
            blurMax: Style.cardShadowExtent
        }
    }

    // Over the fill, under the content: declared first, so children the
    // caller adds paint above it. The Rectangle keeps the fill; the shader
    // adds only the edge colour (see shaders/cardglow.frag).
    ShaderEffect {
        anchors.fill: parent
        visible: root.glow
        fragmentShader: Qt.resolvedUrl("../shaders/cardglow.frag.qsb")

        // Not `size` or `radius`: names Qt already owns on an Item or a
        // Rectangle load as FINAL overrides and fail the whole config.
        property size cardSize: Qt.size(root.width, root.height)
        property real cornerRadius: root.radius
        property vector4d tint: Qt.vector4d(Style.edgeColor.r, Style.edgeColor.g,
            Style.edgeColor.b, Style.edgeStrength)
        property real edgeFade: Style.edgeFade
    }
}
