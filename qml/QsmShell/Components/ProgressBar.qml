import QtQuick

import qs.QsmShell.Style

// "This is running, and here is how far." The determinate half of the pair
// `Spinner` opens: use this whenever a total is knowable, and a spinner only
// when it is not.
//
// `indeterminate` is a real state, not a decoration, and it deliberately does
// NOT look like a full bar creeping forward. A bar that moves without tracking
// anything is a lie the size of the whole component, and one fake bar costs
// the trust of every real one — so the unknown state is a band SWEEPING across
// an empty track, which is visibly a different mark rather than a slower
// version of the same one.
Rectangle {
    id: root

    // 0..1. Ignored while `indeterminate`.
    property real value: 0
    property bool indeterminate: false
    property color fill: Style.accent
    property color trackColor: Style.surfaceHover
    property real thickness: Style.trackThickness

    readonly property real _fraction: Math.max(0, Math.min(1, value))

    implicitHeight: thickness
    radius: height / 2
    color: trackColor
    clip: true
    opacity: enabled ? 1 : Style.opacityDisabled

    // Determinate: a lead that grows from the start edge.
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.indeterminate
        width: parent.width * root._fraction
        height: parent.height
        radius: parent.radius
        color: root.fill

        // Progress that snaps between readings reads as jitter rather than as
        // movement; it eases at both ends because neither end is an arrival.
        Behavior on width {
            NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
        }
    }

    // Indeterminate: a short band crossing an otherwise empty track.
    Rectangle {
        id: sweep
        visible: root.indeterminate
        y: 0
        width: parent.width * 0.3
        height: parent.height
        radius: parent.radius
        color: root.fill

        XAnimator {
            target: sweep
            from: -sweep.width
            to: root.width
            duration: Motion.spin * 2
            loops: Animation.Infinite
            // Eased at both ends: a band at constant speed reads as a
            // conveyor belt, which suggests throughput rather than waiting.
            easing.type: Motion.moveEasing
            running: root.indeterminate && root.visible
        }
    }
}
