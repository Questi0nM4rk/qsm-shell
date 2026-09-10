import QtQuick

import qs.QsmShell.Style

// A LEVEL: how full something is right now. A battery, a disk, a signal, the
// volume as it currently stands.
//
// It is not a `ProgressBar`, and the split is deliberate rather than
// historical — HTML draws the same line for the same reason. A progress bar
// measures a process moving toward an end, so it owns an indeterminate state
// and never changes colour as it fills. A meter measures a quantity that has
// no end, so it owns THRESHOLDS and has no indeterminate state: a level is
// always known, and a level being low is news.
//
// It is not a disabled `Slider` either. A slider is an input and offers the
// pointer a hand; a meter is an output and must not, because a hand that
// cannot grasp anything is a promise the surface will not keep. Disabling a
// slider says "you cannot change this NOW"; a meter says "this was never
// yours to change".
//
// Colour never carries the reading on its own — the FILL does. `low` and
// `high` only tint what the length already says.
Rectangle {
    id: root

    // 0..1
    property real value: 0
    // Below `low`, the level is a problem; above `high` it is. Set the one
    // that applies: a battery is bad when low, a temperature when high. Out
    // of range (the default) means no threshold on that side.
    property real low: -1
    property real high: -1
    property color fill: Style.accent
    property color trackColor: Style.outline
    property real thickness: Style.trackThickness
    property int orientation: Qt.Horizontal

    readonly property bool vertical: orientation === Qt.Vertical
    readonly property real _fraction: Math.max(0, Math.min(1, value))
    readonly property bool _breached: (low >= 0 && _fraction <= low) || (high >= 0 && _fraction >= high)
    // Breaching a threshold is a WARNING, not a failure: the level is doing
    // exactly what it should, it is the reading that is unwelcome. Danger is
    // reserved for something that went wrong.
    readonly property color _fill: _breached ? Style.warning : fill

    implicitWidth: vertical ? thickness : 0
    implicitHeight: vertical ? 0 : thickness
    radius: (vertical ? width : height) / 2
    color: trackColor
    opacity: enabled ? 1 : Style.opacityDisabled

    Rectangle {
        // Vertical fills from the bottom: "more" belongs upward, the same
        // direction a person expects a level to rise.
        anchors.left: parent.left
        anchors.right: root.vertical ? parent.right : undefined
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        width: root.vertical ? undefined : parent.width * root._fraction
        height: root.vertical ? parent.height * root._fraction : parent.height
        radius: parent.radius
        color: root._fill

        // A level that snaps between readings reads as jitter. Both ends of
        // the move already exist, so it eases at both.
        Behavior on width {
            NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
        }
        Behavior on height {
            NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
        }
        Behavior on color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }
}
