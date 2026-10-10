import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    IconButton {
        id: button
        anchors.centerIn: parent
        icon: "check"
        accessibleName: "Apply"
        onClicked: root.eventRecorder?.("intent", "clicked", {})
    }

    readonly property var controls: [
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
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
