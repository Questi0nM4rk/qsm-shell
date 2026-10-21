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
    // sm | md | lg -- a preset NAME, resolved through the theme's size table.
    property string size: "md"
    // The one absolute number; everything else is a proportion of it. The
    // preset is only the DEFAULT: a host that wants a switch across a screen
    // or inside a dense row states its own.
    property real knobSize: Style.size("Switch", size)
    // One scale per instance: everything the switch draws is a proportion
    // of `knobSize`, so this ratio against md is the one number a host
    // composing around it needs to follow.
    readonly property real _s: root.knobSize / Style.size("Switch", "md")
    readonly property real sizeScale: root._s

    signal toggleRequested(bool checked)

    // Every route is this one call: pointer (the hit target below), Space (the
    // template clicks on Space), Return and keypad Enter (below) and a caller.
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
    // amount at both ends, so the travel is what is left over. The inset is
    // the knob's own eighth, rounded to a whole pixel so no size puts the knob
    // on a half pixel.
    readonly property real _knob: root.knobSize
    readonly property real _inset: Math.round(root.knobSize * Style.spaceTight / Style.iconSm)
    implicitWidth: _knob * 2 + _inset * 2
    implicitHeight: _knob + _inset * 2
    padding: 0

    onClicked: root.flip()
    Keys.onReturnPressed: root.flip()
    Keys.onEnterPressed: root.flip()

    // Off: the track is a line (`textMuted`) and the knob a band-coloured dot. On: a
    // toggle with its own fill is selected as SOLID accent, and content on
    // the accent is textOnPrimary, as the Checkbox mark. Disabled dims every
    // role by colour, never by opacity on the composite.
    background: Rectangle {
        id: track
        radius: Style.radiusPill
        // The track is the body: hover lifts and press deepens its colour
        // through the one state matrix, while the knob grows on hover only.
        color: Style.tone(root.checked ? root.accentColor : Style.textMuted,
            root._hot, root._down, false, root.enabled, root.accentColor)

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
            radius: Style.radiusPill
            color: root.enabled
                ? (root.checked ? Style.textOnPrimary : Style.band)
                : Style.disabled(root.checked ? Style.textOnPrimary : Style.band)

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

    // The pointer target is larger than the painted track and overflows it,
    // centred, so the footprint stays the track's: at least one large icon
    // each way (the 24 px floor of WCAG 2.5.8). The template only hears the
    // pointer inside its own bounds, so this target is the pointer route, and
    // its exclusive grab keeps the template's own click from also firing.
    readonly property bool _hot: root.enabled && (root.hovered || hoverReader.hovered)
    readonly property bool _down: root.enabled && (root.pressed || tapReader.pressed)

    Item {
        id: hit
        anchors.centerIn: parent
        width: Math.max(root.width, Style.iconLg)
        height: Math.max(root.height, Style.iconLg)

        HoverHandler {
            id: hoverReader
            enabled: root.enabled
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            id: tapReader
            enabled: root.enabled
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: {
                root.forceActiveFocus(Qt.MouseFocusReason)
                root.flip()
            }
        }
    }

    // The KNOB answers the pointer, not the track: growing the whole switch
    // makes the travel look like it changed length. The layer is the track
    // itself, so the ring (a gap and a stroke of `spaceTight` outside it,
    // concentric) sits at the documented distance. A press recolours the track
    // and never moves the knob: it already fills the track's height on hover.
    StateLayer {
        anchors.fill: parent
        host: root
        target: knob
        manualHoverOverride: hoverReader.hovered
        manualPressOverride: tapReader.pressed
        hoverScale: (Style.iconSm + Style.space1) / Style.iconSm
        focusRadius: height / 2
    }
}
