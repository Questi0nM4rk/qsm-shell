import QtQuick

import qs.QsmShell.Style

// THE interaction primitive, and THE place every interaction state is defined.
//
// A control has five states, not one: at rest, under the pointer, pressed,
// carrying keyboard focus, and unavailable. Leaving any of them undefined does
// not remove it — it just means the control answers that state by accident.
//
//   rest        nothing. The shell paints no box around a thing at rest.
//   hover       the affordance GROWS. Growth, never tint: a tint paints a box
//               the design deliberately withholds, and a tint that lingers
//               reads as a stuck selection rather than as an answer.
//   press       it pushes in, on its own faster curve, so a click is
//               acknowledged even when the action it starts takes time.
//   focus       an accent ring. This is the one state that CANNOT be growth:
//               a keyboard user needs to know where they are without moving
//               anything, and a ring is the only mark that says "here" while
//               the surface is otherwise still. It exists only while focused,
//               so the resting surface stays boxless.
//   disabled    the host dims itself BY COLOUR -- every painted role through
//               `Style.disabled(colour)`, never `opacity` on the composite,
//               which would dim each child separately and let a translucent
//               thumb show the translucent fill through it. The layer simply
//               stops answering, and stops offering a hand it will not shake.
//
// `target` is what grows, and defaults to the layer's own parent because at
// most call sites the parent IS the affordance. A host that expresses growth
// some other way sets `target: null` and drives `hovered` / `pressed` /
// `focused` / `response` itself.
Item {
    id: root

    // A template host (T.Control and friends) already owns hovered, pressed,
    // visualFocus and enabled. Given one, the layer READS those and stops
    // running handlers of its own, so a control has one source of every
    // state. `var`, not `Item`: the properties live on the control subclass
    // and a typed Item would make every read a qmllint warning.
    property var host: null
    readonly property bool _hosted: host !== null && host !== undefined

    property bool interactive: _hosted ? host.enabled : true
    property Item target: parent
    property real hoverScale: 1.08
    property real pressScale: 0.94

    // Keyboard focus. In host mode it is `visualFocus`, which Qt sets only on
    // keyboard-reason focus, so a click never paints the ring. Otherwise the
    // host's activeFocus, as before.
    property bool focused: _hosted ? host.visualFocus : (root.parent?.activeFocus ?? false)
    // The corner the ring follows. The host states it, because `parent` is a
    // plain Item as far as the type system is concerned and probing it for a
    // radius is a warning plus a guess.
    property real focusRadius: 0
    property color focusColor: Style.accent

    readonly property bool hovered: interactive && (_hosted ? host.hovered : hover.hovered)
    readonly property bool pressed: interactive && (_hosted ? (host.pressed ?? false) : tap.pressed)
    signal clicked

    // A hover-enter that is allowed to CLAIM the selection. A list binds its
    // cursor to this rather than to `hovered`, and then a pointer that never
    // moved cannot take the selection from the keyboard — see
    // Interaction.pointerSelects, which the consumer owns.
    signal hoveredEntered

    onHoveredChanged: {
        if (root.hovered && Interaction.pointerSelects)
            root.hoveredEntered();
    }

    // 1 at rest. Exposed as a number, not merely applied, so a host can drive
    // something more apt than scale with it while still following one curve.
    property real response: pressed ? pressScale : hovered ? hoverScale : 1

    Behavior on response {
        NumberAnimation {
            duration: root.pressed ? Motion.press : Motion.micro
            easing.type: Motion.standardEasing
        }
    }

    Binding {
        target: root.target
        property: "scale"
        value: root.response
        when: root.target !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    // One implementation of the focus ring, so a keyboard user meets the same
    // mark on every control instead of whatever each surface remembered to
    // draw.
    Rectangle {
        anchors.fill: parent
        visible: root.focused && root.interactive
        color: "transparent"
        radius: root.focusRadius
        border.width: 1
        border.color: root.focusColor
        opacity: root.focused ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    HoverHandler {
        id: hover
        enabled: !root._hosted
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        id: tap
        enabled: root.interactive && !root._hosted
        onTapped: root.clicked()
    }
}
