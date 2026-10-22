import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// A Card owns no padding and no action, so the unit plays the host: one inset
// on the rhythm, the title and reading above, and a real control inside to
// show the card passes input through and never takes it.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property color surfaceColor: Style.surface
    property bool glow: true
    property bool shadow: true
    property int cleared: 0

    implicitWidth: card.width + Style.space6 * 2
    implicitHeight: card.height + Style.space6 * 2
    color: Style.band

    Card {
        id: card
        anchors.centerIn: parent
        width: Style.controlWidth
        height: body.implicitHeight + Style.space4 * 2
        surfaceColor: root.surfaceColor
        glow: root.glow
        shadow: root.shadow

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: Style.space4
            spacing: Style.space1

            Prose {
                Layout.fillWidth: true
                role: "title"
                text: "Memory"
            }
            Prose {
                Layout.fillWidth: true
                role: "body"
                text: "31.2 GiB of 32 GiB in use across 14 processes."
            }
            Capsule {
                id: action
                Layout.topMargin: Style.space2
                label: "Free caches"
                size: "sm"
                // The body takes the rung the other side of the card's.
                base: Qt.colorEqual(root.surfaceColor, Style.overlay) ? Style.surface : Style.overlay
                onClicked: {
                    root.cleared++
                    root.eventRecorder?.("intent", "clicked", { cleared: root.cleared })
                }
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

    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        targets: ({ card: () => card, action: () => action }),
        observables: {
            glow: () => card.glow,
            shadow: () => card.shadow,
            raised: () => Qt.colorEqual(card.surfaceColor, Style.overlay),
            "card-focused": () => card.activeFocus,
            "action-focused": () => action.visualFocus,
            cleared: () => root.cleared
        },
        runAction: name => {
            if (name !== "activate")
                return false
            action.activate()
            return true
        }
    })
}
