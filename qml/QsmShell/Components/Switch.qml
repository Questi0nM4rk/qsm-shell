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
// because the knob is somewhere different. Off is an outline and on is solid
// accent, the same pair a Checkbox and a Radio use, so the family reads alike.
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
    // sm | md | lg -- a preset NAME, resolved through the theme's size table.
    property string size: "md"
    // The one absolute number, the knob's diameter; everything else is a
    // proportion of it. The preset is only the DEFAULT: a host that wants a
    // switch across a screen or inside a dense row states its own.
    property real knobSize: Style.size("Switch", size)
    // One scale per instance: the ratio against md is the one number a host
    // composing around the switch needs to follow.
    readonly property real sizeScale: root.knobSize / Style.size("Switch", "md")

    // What a screen reader speaks; a switch has no label slot of its own, so
    // the host names what it throws.
    property string accessibleName: ""

    signal toggleRequested(bool checked)

    // Every route is this one call: pointer (clicked), Space, Return and
    // keypad Enter (ActivationKeys, once on release), the screen reader and a
    // caller.
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
    Accessible.role: Accessible.Switch
    Accessible.checkable: true
    Accessible.checked: root.checked
    Accessible.name: root.accessibleName
    Accessible.onPressAction: root.flip()
    Accessible.onToggleAction: root.flip()

    onClicked: root.flip()
    ActivationKeys {
        id: keys
        available: root.enabled
        onActivated: root.flip()
    }
    Keys.forwardTo: [keys]

    // The track is a pill two knobs wide; one rhythm step of air sits between
    // its edge and the knob at every size, enough to keep the 2 px outline of an
    // off switch clear of the knob. The pointer target is the footprint, and
    // the footprint is at least `Style.targetFloor` tall (WCAG
    // 2.5.8): a track shorter than that is centred in the slack, so the hit
    // zone and the hover zone are one rectangle and nothing overflows it.
    readonly property real _air: Style.space1
    readonly property real _trackHeight: root.knobSize + root._air * 2
    readonly property real _slack: Math.max(0, Style.targetFloor - root._trackHeight) / 2
    implicitWidth: root.knobSize * 2 + root._air * 2
    implicitHeight: root._trackHeight + root._slack * 2
    leftPadding: 0
    rightPadding: 0
    topPadding: root._slack
    bottomPadding: root._slack

    // The pointing hand over the whole target while enabled.
    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    contentItem: Item {
        // Off is the outline of the track, on is its fill: the ring stays and
        // takes the fill's colour, so throwing the switch is one cross-fade on
        // one clock. Hover lifts and press deepens the colour through the one
        // state matrix. The off fill is the SAME colour at no alpha, not
        // "transparent", so the fade never passes through a dark mix.
        Rectangle {
            id: track
            anchors.fill: parent
            radius: Style.radiusPill
            readonly property color _tone: Style.tone(root.checked ? root.accentColor : Style.textMuted,
                root.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)
            color: Qt.alpha(track._tone, root.checked ? 1 : 0)
            border.width: Style.stroke(Style.indicatorWidth, root)
            border.color: track._tone

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }
            Behavior on border.color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }
        }

        // The knob's own box slides; its painted body is what grows, so the
        // slide never carries the growth with it. Both ends already exist, so
        // it eases at both: an arrival curve reads as the knob being thrown.
        Item {
            id: knob
            y: (parent.height - height) / 2
            x: root.checked ? parent.width - width - root._air : root._air
            width: root.knobSize
            height: width

            Behavior on x {
                enabled: !Style.reducedMotion
                NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
            }

            // Off the knob is the outline's colour and lifts with the pointer;
            // on it is the content of the accent. Disabled dims by colour.
            Rectangle {
                anchors.fill: parent
                anchors.margins: -stateLayer.growth
                radius: Style.radiusPill
                color: Style.tone(root.checked ? Style.textOnPrimary : Style.textMuted,
                    !root.checked && root.hovered, !root.checked && stateLayer.pressed, false, root.enabled, root.accentColor)

                Behavior on color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
            }
        }

        // The KNOB answers the pointer, not the track: growing the whole switch
        // makes the travel look like it changed length. Growth is one pixel a
        // side (the air left is the 4 px less the outline), and a press keeps
        // it: the colour deepens and the knob does not shrink back. The layer
        // is the track itself, so the ring (a gap and a stroke outside it,
        // concentric) sits at the documented distance.
        StateLayer {
            id: stateLayer
            anchors.fill: parent
            host: root
            extent: root.knobSize
            hoverScale: Style.reducedMotion ? 1 : 1 + Style.spaceTight / root.knobSize
            pressScale: stateLayer.hoverScale
            manualPressOverride: keys.held
            focusRadius: height / 2
        }
    }
}
