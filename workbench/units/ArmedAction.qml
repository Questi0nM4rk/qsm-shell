import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool destructive: true
    property int fired: 0
    property int disarmed: 0

    color: Style.background
    implicitWidth: Style.controlWidth
    implicitHeight: status.implicitHeight + Style.space4 * 2

    ArmedAction {
        id: guard
        destructive: root.destructive
        confirmLabel: "Confirm remove"
        onFired: {
            root.fired++
            root.eventRecorder?.("intent", "fired", {})
        }
        onDisarmed: {
            root.disarmed++
            root.eventRecorder?.("intent", "disarmed", {})
        }
    }

    Prose {
        id: status
        anchors.centerIn: parent
        role: "body"
        text: guard.armed ? "Armed: confirm remove" : "Disarmed: remove"
    }

    readonly property var controls: [
        { label: "guard", options: [
            { label: "destructive", set: { destructive: true } },
            { label: "safe", set: { destructive: false } }
        ] }
    ]

    readonly property var integration: ({
        events: ["fired", "disarmed"],
        actions: ["trigger", "disarm"],
        keys: {
            "Enter": () => { guard.trigger(); return true },
            "Escape": () => { guard.disarm(); return true }
        },
        observables: {
            armed: () => guard.armed,
            destructive: () => root.destructive,
            fired: () => root.fired,
            disarmed: () => root.disarmed
        },
        runAction: name => {
            if (name === "trigger") { guard.trigger(); return true }
            if (name === "disarm") { guard.disarm(); return true }
            return false
        }
    })
}
