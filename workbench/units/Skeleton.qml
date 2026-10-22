import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string role: "label"
    property real fraction: 1
    property string size: "md"
    property bool loaded: false

    implicitWidth: Style.controlWidth
    implicitHeight: placeholders.implicitHeight
    color: Style.band

    // The same card twice, in one place: the placeholders while the data is
    // on its way and the content that replaces them. Lines stack with no gap,
    // because a line placeholder is a whole line box, so the two stacks are
    // the same height by construction and the surface does not jump.
    Item {
        anchors.centerIn: parent
        width: Style.controlWidth
        height: placeholders.height

        Column {
            id: placeholders
            width: parent.width
            visible: !root.loaded

            Skeleton {
                id: media
                size: root.size
            }
            Skeleton {
                id: lead
                shape: "line"
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

        Column {
            id: content
            width: parent.width
            visible: root.loaded

            Rectangle {
                width: parent.width
                height: Style.size("Control", root.size)
                radius: Style.radiusSm
                color: Style.surface
            }
            Prose {
                width: parent.width
                role: root.role
                text: "Wireless headset"
            }
            Prose {
                width: parent.width
                role: "title"
                text: "Connected"
            }
            Prose {
                width: parent.width
                role: "metadata"
                text: "Last seen 2 min ago"
            }
        }
    }

    // Every knob here is a property of the type: a placeholder has no pointer,
    // so a role, a preset and a width are only reachable this way.
    readonly property var controls: [
        // The role of the lead line, the second row of the card.
        { label: "role", options: [
            { label: "hero", set: { role: "hero" } },
            { label: "display", set: { role: "display" } },
            { label: "heading", set: { role: "heading" } },
            { label: "title", set: { role: "title" } },
            { label: "body", set: { role: "body" } },
            { label: "label", set: { role: "label" } },
            { label: "metadata", set: { role: "metadata" } }
        ] },
        // The preset of the block, the first row of the card.
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "width", options: [
            { label: "full", set: { fraction: 1 } },
            { label: "short", set: { fraction: 0.6 } }
        ] },
        { label: "data", options: [
            { label: "loading", set: { loaded: false } },
            { label: "loaded", set: { loaded: true } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            role: () => lead.role,
            fraction: () => lead.fraction,
            size: () => media.size,
            // How far the surface moves when the data lands: the content's
            // height less the placeholders', in pixels.
            "landing-jump": () => Math.round((content.implicitHeight - placeholders.implicitHeight) * 100) / 100
        }
    })
}
