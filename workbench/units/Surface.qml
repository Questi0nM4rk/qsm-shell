import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Components
import qs.QsmShell.Style

// Surface is a body, not a control, so the unit plays the host a body needs:
// a template button that owns pointer, key and focus, grows the body by the
// layer's whole-pixel `growth`, and toggles `selected` itself.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool selected: variant === "selected"
    property string wall: ""

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: button.height + Style.space4 * 2

    T.AbstractButton {
        id: button
        anchors.centerIn: parent
        width: Style.controlWidth / 2
        height: Style.size("Control", "md")
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        onClicked: {
            root.selected = !root.selected
            root.eventRecorder?.("intent", "clicked", { selected: root.selected })
        }
        Keys.onReturnPressed: event => { event.accepted = true; button.click() }
        Keys.onEnterPressed: event => { event.accepted = true; button.click() }

        background: Surface {
            id: body
            x: -stateLayer.growth
            y: -stateLayer.growth
            width: button.width + 2 * stateLayer.growth
            height: button.height + 2 * stateLayer.growth
            hovered: stateLayer.hovered
            pressed: stateLayer.pressed
            selected: root.selected
            snapEdge: root.wall
        }

        contentItem: Prose {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: body.contentColor
            role: "label"
            text: "Surface body"
        }

        StateLayer {
            id: stateLayer
            anchors.fill: parent
            host: button
            focusRadius: body.radius
        }
    }

    readonly property var controls: [
        { label: "selection", options: [
            { label: "rest", set: { selected: false } },
            { label: "selected", set: { selected: true } }
        ] },
        { label: "wall", options: [
            { label: "free", set: { wall: "" } },
            { label: "left", set: { wall: "left" } },
            { label: "right", set: { wall: "right" } },
            { label: "top", set: { wall: "top" } },
            { label: "bottom", set: { wall: "bottom" } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]

    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        targets: ({ body: () => button, scene: () => root }),
        observables: {
            hovered: () => stateLayer.hovered,
            pressed: () => stateLayer.pressed,
            focused: () => button.visualFocus,
            selected: () => root.selected,
            enabled: () => button.enabled,
            wall: () => body.snapEdge,
            grown: () => body.width > button.width
        },
        runAction: name => {
            if (name !== "activate" || !button.enabled)
                return false
            button.click()
            return true
        }
    })
}
