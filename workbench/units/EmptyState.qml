import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string heading: "No devices match"
    property string restMessage: "Widen the filter, or pair a device to see it here."
    property string message: root.restMessage
    property string glyph: "search"
    property bool actionable: true
    property int clicks: 0

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    EmptyState {
        id: empty
        anchors.centerIn: parent
        width: Style.controlWidth
        title: root.heading
        detail: root.message
        icon: root.glyph

        Capsule {
            id: recovery
            visible: root.actionable
            label: "Pair device"
            icon: "plus"
            size: "sm"
            onClicked: {
                root.clicks++
                root.eventRecorder?.("intent", "clicked", {})
            }
        }
    }

    readonly property var controls: [
        { label: "detail", options: [
            { label: "with-detail", set: { message: root.restMessage } },
            { label: "title-only", set: { message: "" } }
        ] },
        { label: "glyph", options: [
            { label: "shown", set: { glyph: "search" } },
            { label: "none", set: { glyph: "" } }
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
            title: () => empty.title,
            detail: () => empty.detail,
            icon: () => empty.icon,
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
