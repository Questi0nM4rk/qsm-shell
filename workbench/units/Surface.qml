import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool hovered: false
    property bool pressed: false
    property bool selected: variant === "selected"

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: body.height + Style.space4 * 2

    Surface {
        id: body
        anchors.centerIn: parent
        width: Style.controlWidth / 2
        height: Style.controlHeight
        hovered: root.hovered
        pressed: root.pressed
        selected: root.selected

        Prose {
            anchors.centerIn: parent
            role: "label"
            text: "Surface body"
        }
    }

    readonly property var controls: [
        { label: "hover", options: [
            { label: "off", set: { hovered: false } },
            { label: "on", set: { hovered: true } }
        ] },
        { label: "press", options: [
            { label: "off", set: { pressed: false } },
            { label: "on", set: { pressed: true } }
        ] },
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
            hovered: () => body.hovered,
            pressed: () => body.pressed,
            selected: () => body.selected,
            enabled: () => body.enabled
        }
    })
}
