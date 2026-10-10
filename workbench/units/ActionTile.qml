import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool selected: false
    property bool armed: variant === "armed"

    implicitWidth: tile.implicitWidth
    implicitHeight: tile.implicitHeight

    ActionTile {
        id: tile
        anchors.centerIn: parent
        icon: "power"
        label: "Power off"
        confirmLabel: "Confirm?"
        selected: root.selected
        armed: root.armed
        onActivated: root.eventRecorder?.("intent", "activated", { selected: root.selected, armed: root.armed })
    }

    readonly property var controls: [
        { label: "selection", options: [
            { label: "rest", set: { selected: false } },
            { label: "selected", set: { selected: true } }
        ] },
        { label: "armed", options: [
            { label: "off", set: { armed: false } },
            { label: "on", set: { armed: true } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["activated"],
        actions: ["activate"],
        keys: {
            "Space": () => { tile.activate(); return true },
            "Enter": () => { tile.activate(); return true }
        },
        observables: {
            selected: () => root.selected,
            armed: () => root.armed,
            enabled: () => root.enabled,
            "shown-label": () => tile.shownLabel
        },
        runAction: name => {
            if (name !== "activate")
                return false
            tile.activate()
            return true
        }
    })
}
