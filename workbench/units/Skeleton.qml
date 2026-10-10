import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string shape: "block"
    property string role: "label"
    property real fraction: 1

    implicitWidth: Style.controlWidth
    implicitHeight: place.implicitHeight
    color: Style.background

    Column {
        id: place
        anchors.centerIn: parent
        width: Style.controlWidth
        spacing: Style.space1

        Skeleton {
            id: lead
            shape: root.shape
            role: root.role
            fraction: root.fraction
        }
        Skeleton {
            shape: "line"
            role: "title"
        }
        // The last line of a paragraph is short, and three identical bars
        // read as a barcode.
        Skeleton {
            shape: "line"
            role: "metadata"
            fraction: 0.6
        }
    }

    // Every knob here is a property of the type: a placeholder has no pointer,
    // so a shape, a role and a width are only reachable this way.
    readonly property var controls: [
        { label: "shape", options: [
            { label: "block", set: { shape: "block" } },
            { label: "line", set: { shape: "line" } }
        ] },
        { label: "role", options: [
            { label: "hero", set: { role: "hero" } },
            { label: "display", set: { role: "display" } },
            { label: "heading", set: { role: "heading" } },
            { label: "title", set: { role: "title" } },
            { label: "body", set: { role: "body" } },
            { label: "metadata", set: { role: "metadata" } }
        ] },
        { label: "width", options: [
            { label: "full", set: { fraction: 1 } },
            { label: "short", set: { fraction: 0.6 } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            shape: () => lead.shape,
            role: () => lead.role,
            fraction: () => lead.fraction
        }
    })
}
