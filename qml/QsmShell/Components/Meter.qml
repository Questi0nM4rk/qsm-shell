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
// `high` only tint what the length already says, and `breached` reports the
// same fact for a host that wants a second cue beside the bar.
Rectangle {
    id: root

    // 0..1
    property real value: 0
    // Below `low`, the level is a problem; above `high` it is. Set the one
    // that applies: a battery is bad when low, a temperature when high. Out
    // of range (the default) means no threshold on that side.
    property real low: -1
    property real high: -1
    property color fill: Style.primary
    property color trackColor: Style.overlay
    property real thickness: Style.stroke(Style.trackThickness, root)
    property int orientation: Qt.Horizontal
    property string accessibleName: ""

    readonly property bool vertical: orientation === Qt.Vertical
    readonly property real _fraction: Math.max(0, Math.min(1, value))
    // The eased fraction the fill is drawn from. Easing the fraction and not
    // the pixel size means a host resize moves the fill with the track and
    // only a change of value glides. Reduced motion removes the glide.
    property real _shown: _fraction
    Behavior on _shown {
        enabled: !Style.reducedMotion
        NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
    }
    // Whether the reading is past a threshold: what tints the fill.
    readonly property bool _belowLow: low >= 0 && _fraction <= low
    readonly property bool breached: _belowLow || (high >= 0 && _fraction >= high)
    // Breaching a threshold is a WARNING, not a failure: the level is doing
    // exactly what it should, it is the reading that is unwelcome. Danger is
    // reserved for something that went wrong.
    readonly property color _fill: breached ? Style.warning : fill
    // Disabled dims every role BY COLOUR, never by opacity on the composite:
    // a translucent fill would show through a translucent track and the two
    // would stop being two layers.
    readonly property color _paintedTrack: root.enabled ? root.trackColor : Style.disabled(root.trackColor)
    readonly property color _paintedFill: root.enabled ? root._fill : Style.disabled(root._fill)

    implicitWidth: vertical ? thickness : 0
    implicitHeight: vertical ? 0 : thickness
    radius: Style.radiusPill
    antialiasing: false
    color: root._paintedTrack

    // An output with no hand: a level, announced with its reading and, past a
    // threshold, which side.
    Accessible.role: Accessible.Indicator
    Accessible.name: root.accessibleName
    Accessible.description: Math.round(root._fraction * 100) + "%"
        + (root.breached ? (root._belowLow ? ", low" : ", high") : "")

    Rectangle {
        objectName: "meterFill"
        // The fill is the track less what is not filled, anchored from the
        // start edge: left (right when mirrored), or bottom, because "more"
        // belongs upward, the direction a person expects a level to rise.
        // Margins, not anchors that come and go: an anchor a ternary sets to
        // `undefined` is not withdrawn, so a meter that changed orientation
        // collapsed its fill to a dot.
        anchors.fill: parent
        anchors.rightMargin: root.vertical ? 0 : parent.width - Math.round(parent.width * root._shown)
        anchors.topMargin: root.vertical ? parent.height - Math.round(parent.height * root._shown) : 0
        radius: parent.radius
        antialiasing: false
        color: root._paintedFill

        // A level that snaps between readings reads as jitter, so the value
        // eases (see `_shown`); the colour change stays under reduced motion.
        Behavior on color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }
}
