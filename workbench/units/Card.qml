import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property color surfaceColor: Style.surface
    property real surfaceOpacity: Style.surfaceOpacity

    implicitWidth: card.width
    implicitHeight: card.height
    color: Style.band

    Card {
        id: card
        anchors.centerIn: parent
        width: Style.controlWidth
        height: body.implicitHeight + Style.space2 * 2
        surfaceColor: root.surfaceColor
        surfaceOpacity: root.surfaceOpacity

        Column {
            id: body
            anchors.fill: parent
            anchors.margins: Style.space2
            spacing: Style.space1

            Prose {
                width: parent.width
                role: "title"
                text: "Memory"
            }
            Prose {
                width: parent.width
                role: "body"
                text: "31.2 GiB of 32 GiB in use across 14 processes."
            }
        }
    }

    readonly property var controls: [
        { label: "surface", options: [
            { label: "resting", set: { surfaceColor: Style.surface, surfaceOpacity: Style.surfaceOpacity } },
            { label: "raised", set: { surfaceColor: Style.surface, surfaceOpacity: Style.surfaceOpacity } },
            { label: "opaque", set: { surfaceColor: Style.surface, surfaceOpacity: 1 } }
        ] }
    ]
}
