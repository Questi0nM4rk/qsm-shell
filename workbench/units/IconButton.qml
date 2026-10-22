import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string size: "md"
    property bool selected: false

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    IconButton {
        id: button
        anchors.centerIn: parent
        icon: "check"
        accessibleName: "Apply"
        size: root.size
        selected: root.selected
        onClicked: root.eventRecorder?.("intent", "clicked", {})
    }

    readonly property var controls: [
        { label: "size", options: [
            { label: "xs", set: { size: "xs" } },
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] },
        { label: "toggle", options: [
            { label: "off", set: { selected: false } },
            { label: "on", set: { selected: true } }
        ] }
    ]
    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        keys: {
            "Space": () => { button.activate(); return true },
            "Enter": () => { button.activate(); return true }
        },
        observables: { enabled: () => root.enabled },
        runAction: name => {
            if (name !== "activate")
                return false
            button.activate()
            return true
        }
    })
}
