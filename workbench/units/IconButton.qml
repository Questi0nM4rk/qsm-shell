import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property int size: Style.iconMd
    property int padding: Style.space3

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    IconButton {
        id: button
        anchors.centerIn: parent
        icon: "check"
        accessibleName: "Apply"
        size: root.size
        padding: root.padding
        onClicked: root.eventRecorder?.("intent", "clicked", {})
    }

    readonly property var controls: [
        { label: "size", options: [
            { label: "iconXs", set: { size: Style.iconXs } },
            { label: "iconSm", set: { size: Style.iconSm } },
            { label: "iconMd", set: { size: Style.iconMd } }
        ] },
        { label: "padding", options: [
            { label: "default", set: { padding: Style.space3 } },
            { label: "compact", set: { padding: Style.space1 } }
        ] },
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
