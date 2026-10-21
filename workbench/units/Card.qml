import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property color surfaceColor: Style.surface
    property bool glow: true
    property bool shadow: true

    implicitWidth: card.width
    implicitHeight: card.height
    color: Style.band

    Card {
        id: card
        anchors.centerIn: parent
        width: Style.controlWidth
        height: body.implicitHeight + Style.space2 * 2
        surfaceColor: root.surfaceColor
        glow: root.glow
        shadow: root.shadow

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
            { label: "resting", set: { surfaceColor: Style.surface } },
            { label: "raised", set: { surfaceColor: Style.overlay } }
        ] },
        { label: "glow", options: [
            { label: "on", set: { glow: true } },
            { label: "off", set: { glow: false } }
        ] },
        { label: "shadow", options: [
            { label: "on", set: { shadow: true } },
            { label: "off", set: { shadow: false } }
        ] }
    ]
}
