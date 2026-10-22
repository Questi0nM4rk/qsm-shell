import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// Hosts centre an EmptyState and give it no width, so the unit does the same
// and the type's own ceiling is what holds a long copy in.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    readonly property string restHeading: "No devices match"
    readonly property string restMessage: "Widen the filter, or pair a device to see it here."
    property string heading: root.restHeading
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
            { label: "title-only", set: { message: "" } },
            { label: "long", set: { message: "The Bluetooth adapter reported that no paired device matches this filter. "
                + "Widen the filter, clear the search, or pair a device from the Bluetooth settings to see it here." } }
        ] },
        { label: "title", options: [
            { label: "short", set: { heading: root.restHeading } },
            { label: "long", set: { heading: "No paired Bluetooth device matches the filter you have typed so far" } }
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
        targets: ({ recovery: () => recovery, message: () => empty, scene: () => root }),
        observables: {
            title: () => empty.title,
            detail: () => empty.detail,
            icon: () => empty.icon,
            "accessible-name": () => empty.Accessible.name,
            width: () => empty.width,
            height: () => empty.height,
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
