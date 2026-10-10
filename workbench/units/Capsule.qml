import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool active: variant === "active"

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Capsule {
        id: pill
        anchors.centerIn: parent
        icon: "sparkle"
        label: "Wireless"
        active: root.active
        onClicked: {
            root.active = !root.active
            root.eventRecorder?.("intent", "clicked", { active: root.active })
        }
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
            "Space": () => { pill.activate(); return true },
            "Enter": () => { pill.activate(); return true }
        },
        observables: { active: () => root.active },
        runAction: name => {
            if (name !== "activate")
                return false
            pill.activate()
            return true
        }
    })
}
