import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property string role: "heading"
    property bool muted: false
    property bool technical: false
    readonly property bool ladderMode: variant === "default"

    readonly property var ladder: ["hero", "display", "heading", "title", "body",
        "label", "supporting", "metadata", "reading", "section"]

    implicitWidth: Style.controlWidth
    implicitHeight: root.ladderMode ? Style.controlWidth * 2 : Style.controlHeightLg + Style.space6 * 2

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: Style.space2

        Prose {
            visible: !root.ladderMode
            id: specimen
            Layout.fillWidth: true
            text: "Quiet Luminous"
            role: root.role
            muted: root.muted
            technical: root.technical
        }

        Prose {
            visible: !root.ladderMode
            Layout.fillWidth: true
            role: "body"
            text: "A calm dark shell stays subordinate to the application beneath it."
        }

        Repeater {
            id: ladderRows
            model: root.ladderMode ? root.ladder : []

            Prose {
                required property string modelData
                Layout.fillWidth: true
                role: modelData
                text: modelData
            }
        }
    }

    readonly property var controls: [
        { label: "role", options: [
            { label: "hero", set: { role: "hero" } },
            { label: "display", set: { role: "display" } },
            { label: "heading", set: { role: "heading" } },
            { label: "title", set: { role: "title" } },
            { label: "body", set: { role: "body" } },
            { label: "label", set: { role: "label" } },
            { label: "supporting", set: { role: "supporting" } },
            { label: "metadata", set: { role: "metadata" } },
            { label: "reading", set: { role: "reading" } },
            { label: "section", set: { role: "section" } }
        ] },
        { label: "muted", options: [
            { label: "on", set: { muted: true } },
            { label: "off", set: { muted: false } }
        ] },
        { label: "technical", options: [
            { label: "on", set: { technical: true } },
            { label: "off", set: { technical: false } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            role: () => specimen.role,
            "ladder-mode": () => root.ladderMode,
            muted: () => specimen.muted,
            technical: () => specimen.technical,
            "wraps": () => specimen.wrapMode !== Text.NoWrap,
            "ladder-roles": () => ladderRows.count
        },
        runAction: () => false
    })
}
