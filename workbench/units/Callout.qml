import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string toneName: variant.length > 0 ? variant : "info"
    readonly property string restHeading: "Output device is not available"
    readonly property string restMessage: "The dock was unplugged. Reconnect it, or pick another output."
    readonly property string longHeading: "The output device the session was using is not available any more"
    readonly property string longMessage: "The dock was unplugged while audio was playing, so the session lost its output. "
        + "Reconnect the dock to resume exactly where it stopped, pick another output from the list, "
        + "or keep the sound muted until a device is available."
    property string heading: root.restHeading
    property string message: root.restMessage
    property string mark: ""
    property bool actionable: true
    property int clicks: 0

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

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
            { label: "with-body", set: { heading: root.restHeading, message: root.restMessage } },
            { label: "title-only", set: { heading: root.restHeading, message: "" } },
            { label: "long", set: { heading: root.longHeading, message: root.longMessage } },
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
        targets: ({ message: () => note, retry: () => recovery, scene: () => root }),
        observables: {
            tone: () => note.tone,
            title: () => note.title,
            body: () => note.body,
            icon: () => note.icon,
            interrupts: () => note.Accessible.role === Accessible.AlertMessage,
            "accessible-name": () => note.Accessible.name,
            height: () => note.height,
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
