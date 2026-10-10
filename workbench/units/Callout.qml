import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string toneName: variant.length > 0 ? variant : "info"
    property string heading: "Output device is not available"
    property string restMessage: "The dock was unplugged. Reconnect it, or pick another output."
    property string message: root.restMessage
    property string mark: ""
    property bool actionable: true
    property int clicks: 0

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.background

    Callout {
        id: note
        anchors.centerIn: parent
        width: Style.controlWidth
        tone: root.toneName
        title: root.heading
        body: root.message
        icon: root.mark

        Capsule {
            id: recovery
            visible: root.actionable
            label: "Retry"
            size: "sm"
            variant: "secondary"
            onClicked: {
                root.clicks++
                root.eventRecorder?.("intent", "clicked", {})
            }
        }
    }

    readonly property var controls: [
        { label: "tone", options: [
            { label: "info", set: { toneName: "info" } },
            { label: "success", set: { toneName: "success" } },
            { label: "warning", set: { toneName: "warning" } },
            { label: "danger", set: { toneName: "danger" } }
        ] },
        { label: "copy", options: [
            { label: "with-body", set: { message: root.restMessage } },
            { label: "title-only", set: { message: "" } },
            { label: "bare", set: { heading: "", message: "" } }
        ] },
        { label: "mark", options: [
            { label: "tone", set: { mark: "" } },
            { label: "stated", set: { mark: "wifi-off" } }
        ] },
        { label: "action", options: [
            { label: "recovery", set: { actionable: true } },
            { label: "none", set: { actionable: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        observables: {
            tone: () => note.tone,
            title: () => note.title,
            body: () => note.body,
            icon: () => note.icon,
            clicks: () => root.clicks
        },
        runAction: name => {
            if (name !== "activate")
                return false
            recovery.activate()
            return true
        }
    })
}
