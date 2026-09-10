import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// A boolean that takes effect the moment it is thrown.
//
// That is the trigger, and it is what separates this from a checkbox: a switch
// is an ACTION (turn wifi off, now), a checkbox is a STATEMENT that something
// else will later act on (include this in the selection). Using a switch for
// a value that only applies on save is a promise the interface does not keep.
//
// The knob's position carries the state, not its colour: a switch read in a
// glance, or by someone who cannot separate the two hues, is still legible
// because the knob is somewhere different.
//
// The HOST owns `checked`: this emits `toggleRequested` and never writes its
// own state, so a setting the system can also change from elsewhere never
// fights the control that shows it. Hence `T.AbstractButton` with
// `checkable: false`, not `T.Switch`: measured, `T.Switch` writes `checked`
// itself on a drag release even when it is not checkable, which takes the
// state away from the host. Drag is the one thing given up for that.
T.AbstractButton {
    id: root

    property color accentColor: Style.accent

    signal toggleRequested(bool checked)

    // Every route is this one call: pointer (clicked), Space (the template
    // clicks on Space), Return (below) and a caller.
    function flip(): void {
        if (root.enabled)
            root.toggleRequested(!root.checked);
    }

    readonly property list<T.Action> actions: [
        T.Action { text: "Toggle"; enabled: root.enabled; onTriggered: root.flip() }
    ]

    checkable: false
    activeFocusOnTab: enabled
    hoverEnabled: true
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true

    // The track is a pill two knobs wide; the knob is inset by the same
    // amount at both ends, so the travel is what is left over. Constant.
    readonly property real _knob: Style.iconSm
    readonly property real _inset: Style.spaceTight
    implicitWidth: _knob * 2 + _inset * 2
    implicitHeight: _knob + _inset * 2
    padding: 0

    onClicked: root.flip()
    Keys.onReturnPressed: root.flip()

    // Off: the track is a line (`outline`) and the knob a muted mark. On: a
    // toggle with its own fill is selected as SOLID accent, and content on
    // the accent is the background, as the Checkbox mark. Disabled dims every
    // role by colour, never by opacity on the composite.
    background: Rectangle {
        id: track
        radius: height / 2
        color: root.enabled
            ? (root.checked ? root.accentColor : Style.outline)
            : Style.disabled(root.checked ? root.accentColor : Style.outline)

        Behavior on color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    contentItem: Item {
        Rectangle {
            id: knob
            y: (parent.height - height) / 2
            x: root.checked ? root.width - width - root._inset : root._inset
            width: root._knob
            height: width
            radius: width / 2
            color: root.enabled
                ? (root.checked ? Style.background : Style.textMuted)
                : Style.disabled(root.checked ? Style.background : Style.textMuted)

            // The knob SLIDES: both ends already exist, so it eases at both.
            // An arrival curve here reads as the knob being thrown.
            Behavior on x {
                enabled: !Style.reducedMotion
                NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
            }
            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }
        }
    }

    // The KNOB answers the pointer, not the track: growing the whole switch
    // makes the travel look like it changed length. It grows on press rather
    // than shrinking: a press is a lift. The ring is the track's outline at a
    // half step (surface ladder), so the layer is the track plus the gap.
    StateLayer {
        anchors.centerIn: parent
        width: root.width + Style.spaceTight * 2
        height: root.height + Style.spaceTight * 2
        host: root
        target: knob
        hoverScale: (root._knob + Style.space1) / root._knob
        pressScale: (root._knob + Style.space2) / root._knob
        focusRadius: height / 2
    }
}
