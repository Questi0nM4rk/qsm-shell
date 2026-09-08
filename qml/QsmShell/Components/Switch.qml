import QtQuick

import qs.QsmShell.Style

// A boolean that takes effect the moment it is thrown.
//
// That is the trigger, and it is what separates this from a checkbox: a switch
// is an ACTION (turn wifi off, now), a checkbox is a STATEMENT that something
// else will later act on (include this in the selection). Using a switch for
// a value that only applies on save is a promise the interface does not keep.
//
// The knob's position carries the state, not its colour — a switch read in a
// glance, or by someone who cannot separate the two hues, is still legible
// because the knob is somewhere different.
//
// The HOST owns `checked`: this emits `toggled` and never writes its own
// state, so a setting the system can also change from elsewhere never fights
// the control that shows it.
Item {
    id: root

    // The keyboard handlers need a real Tab route; disabled switches must leave
    // that route at the same time as their pointer and key actions.
    activeFocusOnTab: enabled

    property bool checked: false
    property color accentColor: Style.accent
    // Keyboard focus. Defaults to this item's own, so a switch that takes
    // focus rings without wiring; a list that owns focus for its rows binds it.
    property bool focused: root.activeFocus

    signal toggled(bool checked)

    // The track is a pill two knobs wide; the knob is inset by the same
    // amount at both ends, so the travel is what is left over.
    readonly property real _knob: Style.iconSm
    readonly property real _inset: Style.spaceTight

    implicitWidth: _knob * 2 + _inset * 2
    implicitHeight: _knob + _inset * 2
    opacity: enabled ? 1 : Style.opacityDisabled

    Behavior on opacity {
        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.55)
            : Style.surfaceHover

        Behavior on color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    Rectangle {
        id: knob
        y: root._inset
        x: root.checked ? root.width - width - root._inset : root._inset
        width: root._knob
        height: width
        radius: width / 2
        color: root.checked ? root.accentColor : Style.textMuted

        // The knob SLIDES: both ends already exist, so it eases at both. An
        // arrival curve here reads as the knob being thrown rather than moved.
        Behavior on x {
            NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
        }
        Behavior on color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    StateLayer {
        anchors.fill: parent
        // The KNOB answers the pointer, not the track: growing the whole
        // switch makes the travel look like it changed length.
        target: knob
        interactive: root.enabled
        focused: root.focused
        focusRadius: height / 2
        hoverScale: 1.12
        pressScale: 0.9
        onClicked: root.toggled(!root.checked)
    }

    Keys.onSpacePressed: if (root.enabled) root.toggled(!root.checked)
    Keys.onReturnPressed: if (root.enabled) root.toggled(!root.checked)
}
