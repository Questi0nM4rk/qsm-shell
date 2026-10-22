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
    property color fill: Style.primary
    property color trackColor: Style.overlay
    property real thickness: Style.stroke(Style.trackThickness, root)
    property string accessibleName: ""

    readonly property real _fraction: Math.max(0, Math.min(1, value))
    // The band is a share of the track: long enough to read as motion on a
    // short bar, short enough to read as "somewhere in it" on a long one.
    readonly property real _bandShare: 0.3
    readonly property color _paintedFill: enabled ? fill : Style.disabled(fill)
    // Unknown work is only shown while there is work: a disabled bar is a
    // still, dimmed track, never a band that keeps travelling.
    readonly property bool _sweeping: indeterminate && enabled

    implicitHeight: thickness
    radius: Style.radiusPill
    antialiasing: false
    color: enabled ? trackColor : Style.disabled(trackColor)
    clip: true

    // A bar with no total reports no value, so a screen reader announces the
    // work and, when there is a total, the percentage.
    Accessible.role: Accessible.ProgressBar
    Accessible.name: root.accessibleName
    Accessible.description: root.indeterminate ? "" : Math.round(root._fraction * 100) + "%"

    // Determinate: a lead that grows from the start edge.
    Rectangle {
        objectName: "progressFill"
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.indeterminate
        width: parent.width * root._fraction
        height: parent.height
        radius: parent.radius
        antialiasing: false
        color: root._paintedFill

        // Progress that snaps between readings reads as jitter rather than as
        // movement; it eases at both ends because neither end is an arrival.
        // Reduced motion removes the slide rather than shortening it.
        Behavior on width {
            enabled: !Style.reducedMotion
            NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
        }
    }

    // Indeterminate: a short band crossing an otherwise empty track.
    Rectangle {
        id: sweep
        objectName: "progressSweep"
        visible: root._sweeping
        y: 0
        width: parent.width * root._bandShare
        height: parent.height
        radius: parent.radius
        antialiasing: false
        color: root._paintedFill

        XAnimator {
            target: sweep
            from: -sweep.width
            to: root.width
            duration: Motion.spin * 2
            loops: Animation.Infinite
            // Eased at both ends: a band at constant speed reads as a
            // conveyor belt, which suggests throughput rather than waiting.
            easing.type: Motion.moveEasing
            running: root._sweeping && root.visible
        }
    }
}
