import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool checked: variant === "on"

    implicitWidth: toggle.implicitWidth
    implicitHeight: toggle.implicitHeight

    Switch {
        id: toggle
        anchors.centerIn: parent
        checked: root.checked
        onToggleRequested: next => {
            root.checked = next
            root.eventRecorder?.("intent", "toggle-requested", { checked: next })
        }
    }

    readonly property var controls: [
        { label: "checked", options: [
            { label: "on", set: { checked: true } },
            { label: "off", set: { checked: false } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["toggle-requested"],
        actions: ["toggle"],
        keys: {
            "Space": () => { toggle.flip(); return true },
            "Enter": () => { toggle.flip(); return true }
        },
        observables: { checked: () => root.checked },
        runAction: name => {
            if (name !== "toggle")
                return false
            toggle.flip()
            return true
        }
    })
}
