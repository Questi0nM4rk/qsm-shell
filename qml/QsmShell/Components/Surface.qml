import QtQuick

import qs.QsmShell.Style

// THE body of a component: one rectangle whose colour is the surface ladder's
// answer to where it lies (`base`) and what it is doing (hovered, pressed,
// selected, enabled). A component that wrote its own state ternary and its
// own Behavior would disagree with the next one on the selected tint.
//
//     background: Surface { base: Style.surface; hovered: root.hovered; selected: root.checked }
//
// `pressed` is for bodies that cannot grow (rows, text); a control that grows
// through StateLayer leaves it false. `contentColor` is what text and glyphs
// on this body wear: accent while selected, the text role otherwise, dimmed
// with the body. Hosts read it and never assign it.
Rectangle {
    id: root

    property color base: Style.surface
    property color accent: Style.accent
    property bool hovered: false
    property bool pressed: false
    property bool selected: false
    // A bare Surface is a finished body, not a square: the room's body radius.
    radius: Style.radiusBody
    // The wall this body sits flush against, "left", "right", "top" or
    // "bottom": the two corners on that side go square and the others keep
    // `radius`. A rail cell against the frame must not round into the wall.
    property string snapEdge: ""
    readonly property bool _edgeKnown: ["", "left", "right", "top", "bottom"].includes(snapEdge)
    on_EdgeKnownChanged: _checkEdge()
    Component.onCompleted: _checkEdge()
    function _checkEdge() {
        if (!_edgeKnown)
            console.error(`Surface: unknown snapEdge "${snapEdge}" -- expected left, right, top, bottom or ""`);
    }

    property color contentColor: root.enabled
        ? (root.selected ? root.accent : Style.text)
        : Style.disabled(root.selected ? root.accent : Style.text)

    // Each corner names its radius outright: a corner assigned -1 rendered
    // square, so every Surface lost its rounding.
    topLeftRadius: root.snapEdge === "left" || root.snapEdge === "top" ? 0 : root.radius
    topRightRadius: root.snapEdge === "right" || root.snapEdge === "top" ? 0 : root.radius
    bottomLeftRadius: root.snapEdge === "left" || root.snapEdge === "bottom" ? 0 : root.radius
    bottomRightRadius: root.snapEdge === "right" || root.snapEdge === "bottom" ? 0 : root.radius

    color: Style.tone(root.base, root.hovered, root.pressed, root.selected, root.enabled, root.accent)

    Behavior on color {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    // Same curve as the fill, so a label never lands before its body.
    Behavior on contentColor {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }
}
