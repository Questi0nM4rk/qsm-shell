import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool selected: variant === "selected"

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: body.height + Style.space4 * 2

    Surface {
        id: body
        anchors.centerIn: parent
        width: Style.controlWidth / 2
        height: Style.size("Control", "md")
        radius: Style.radiusMd
        hovered: stateLayer.hovered
        pressed: stateLayer.pressed
        selected: root.selected

        StateLayer {
            id: stateLayer
            anchors.fill: parent
            interactive: root.enabled
            focusRadius: body.radius
        }

        Prose {
            anchors.centerIn: parent
            color: body.contentColor
            role: "label"
            text: "Surface body"
        }
    }

    readonly property var controls: [
        { label: "selection", options: [
            { label: "rest", set: { selected: false } },
            { label: "selected", set: { selected: true } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            hovered: () => stateLayer.hovered,
            pressed: () => stateLayer.pressed,
            selected: () => body.selected,
            enabled: () => body.enabled
        }
    })
}
