import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""

    // The rule's own properties, set by a case or by a single control.
    property real inset: Style.space3
    property bool inBand: false
    // 0 means the rule's natural width: the card's width minus nothing.
    property real ruleWidth: 0
    // 0 means the rule's natural height; the item may claim a gap around the ink.
    property real gap: 0
    property bool turned: false
    property bool heading: false
    property color ground: Style.band

    implicitWidth: Style.controlWidth
    implicitHeight: column.implicitHeight
    color: Style.band

    Rectangle {
        anchors.centerIn: parent
        width: Style.controlWidth
        height: column.implicitHeight
        color: root.ground

        Column {
            id: column
            anchors.fill: parent
            spacing: Style.space3

            Prose {
                width: parent.width
                text: "Displays"
            }

            RowLayout {
                visible: root.heading
                width: parent.width
                spacing: Style.space2

                Divider { Layout.fillWidth: true; inBand: root.inBand }
                Prose { role: "section"; text: "Section" }
                Divider { Layout.fillWidth: true; inBand: root.inBand }
            }

            Item {
                visible: !root.heading
                width: parent.width
                height: root.turned ? root.ruleWidth : rule.height

                Divider {
                    id: rule
                    anchors.centerIn: root.turned ? parent : undefined
                    width: root.ruleWidth > 0 ? root.ruleWidth : parent.width
                    height: root.gap > 0 ? root.gap : implicitHeight
                    x: root.turned ? 0 : (parent.width - width) / 2
                    inset: root.inset
                    inBand: root.inBand
                    rotation: root.turned ? 90 : 0
                }
            }

            Prose {
                width: parent.width
                text: "Inputs"
            }
        }
    }

    readonly property var controls: [
        { label: "case", options: [
            { label: "surface", set: { inset: Style.space3, inBand: false, ruleWidth: 0, gap: 0, turned: false, heading: false, ground: Style.surface } },
            { label: "list heading", set: { inset: 0, inBand: false, ruleWidth: 0, gap: 0, turned: false, heading: true, ground: Style.surface } },
            { label: "card", set: { inset: Style.notificationDividerInset, inBand: false, ruleWidth: 0, gap: 0, turned: false, heading: false, ground: Style.surface } },
            { label: "short", set: { inset: 0, inBand: false, ruleWidth: Style.space6 * 3, gap: 0, turned: false, heading: false, ground: Style.overlay } },
            { label: "band", set: { inset: Style.space2, inBand: true, ruleWidth: 0, gap: Style.space2, turned: false, heading: false, ground: Style.band } },
            { label: "band turned", set: { inset: 0, inBand: true, ruleWidth: Style.space6 * 2, gap: 0, turned: true, heading: false, ground: Style.band } }
        ] },
        { label: "rule", options: [
            { label: "surface", set: { inBand: false } },
            { label: "band", set: { inBand: true } }
        ] },
        { label: "inset", options: [
            { label: "none", set: { inset: 0 } },
            { label: "space3", set: { inset: Style.space3 } },
            { label: "card", set: { inset: Style.notificationDividerInset } }
        ] }
    ]
}
