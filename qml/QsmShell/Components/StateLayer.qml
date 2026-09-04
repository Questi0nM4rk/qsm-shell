import QtQuick

import qs.QsmShell.Style

Item {
    id: root

    property bool interactive: true
    property Item target: parent
    property real hoverScale: 1.08
    property real pressScale: 0.94
    readonly property bool hovered: hover.hovered
    readonly property bool pressed: interactive && tap.pressed
    signal clicked
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

    HoverHandler {
        id: hover
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        id: tap
        enabled: root.interactive
        onTapped: root.clicked()
    }
}
