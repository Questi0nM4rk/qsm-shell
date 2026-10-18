import QtQuick

import qs.QsmShell.Style

Rectangle {
    id: root

    property color surfaceColor: Style.surface
    property real surfaceOpacity: Style.surfaceOpacity
    // Opt-in: the silhouette's edge separation (a slight line at the edge fading
    // inward), painted inside this card's rounded edge so the card reads as an
    // object, not a traced rectangle.
    property bool glow: false

    color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, surfaceOpacity)
    radius: Style.radiusLg

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
