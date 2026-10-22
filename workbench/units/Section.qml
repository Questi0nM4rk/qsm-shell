import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null

    readonly property string heading: root.variant.length > 0
        ? root.variant.charAt(0).toUpperCase() + root.variant.slice(1)
        : ""
    property bool titled: true
    property bool actioned: true
    property Capsule headingAction: Capsule {
        label: "Refresh"
        size: "sm"
        variant: "ghost"
        onClicked: root.eventRecorder?.("intent", "clicked", {})
    }

    implicitWidth: Style.controlWidth
    implicitHeight: group.implicitHeight
    color: Style.band

    Section {
        id: group
        anchors.centerIn: parent
        width: Style.controlWidth
        title: root.titled ? root.heading : ""
        action: root.actioned ? root.headingAction : null

        KeyValueRow {
            Layout.fillWidth: true
            label: "Displays"
            value: "3"
        }
        KeyValueRow {
            Layout.fillWidth: true
            label: "Keyboard"
            value: "connected"
        }
    }

    // The group has no states of its own, so what a control reaches is the one
    // thing it does decide: whether the header has anything to show.
    readonly property var controls: [
        { label: "header", options: [
            { label: "titled", set: { titled: true, actioned: true } },
            { label: "untitled", set: { titled: false, actioned: true } },
            { label: "bare", set: { titled: false, actioned: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        targets: ({ action: () => root.headingAction }),
        observables: {
            // The header hides itself, so what the group shows is measured, not
            // derived from the control that asked for it.
            "visible-children": () => group.visibleChildren.length
        },
        runAction: name => {
            if (name !== "activate")
                return false
            root.headingAction.activate()
            return true
        }
    })
}
