import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""

    // The rule's own properties, set by a case or by a single control.
    property real inset: Style.space3
    property real strength: .35
    property real thickness: 1
    property color lineColor: Style.textMuted
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

                Divider { Layout.fillWidth: true; strength: root.strength }
                Prose { role: "section"; text: "Section" }
                Divider { Layout.fillWidth: true; strength: root.strength }
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
                    strength: root.strength
                    thickness: root.thickness
                    lineColor: root.lineColor
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
            { label: "default", set: { inset: Style.space3, strength: .35, thickness: 1, lineColor: Style.textMuted, ruleWidth: 0, gap: 0, turned: false, heading: false, ground: Style.band } },
            { label: "list header", set: { inset: 0, strength: .5, thickness: 1, lineColor: Style.textMuted, ruleWidth: 0, gap: 0, turned: false, heading: true, ground: Style.surface } },
            { label: "list separator", set: { inset: Style.space3, strength: .5, thickness: 1, lineColor: Style.textMuted, ruleWidth: 0, gap: 0, turned: false, heading: false, ground: Style.surface } },
            { label: "card bottom", set: { inset: Style.notificationDividerInset, strength: .25, thickness: 1, lineColor: Style.textMuted, ruleWidth: 0, gap: 0, turned: false, heading: false, ground: Style.surface } },
            { label: "menu short", set: { inset: 0, strength: .25, thickness: 1, lineColor: Style.textMuted, ruleWidth: Style.space6 * 3, gap: 0, turned: false, heading: false, ground: Style.overlay } },
            { label: "rail", set: { inset: Style.space2, strength: .8, thickness: Style.space1 / 2, lineColor: Style.textMuted, ruleWidth: 0, gap: Style.space2, turned: false, heading: false, ground: Style.band } },
            { label: "rail turned", set: { inset: 0, strength: .8, thickness: Style.space1 / 2, lineColor: Style.textMuted, ruleWidth: Style.space6 * 2, gap: 0, turned: true, heading: false, ground: Style.band } }
        ] },
        { label: "strength", options: [
            { label: ".25", set: { strength: .25 } },
            { label: ".35", set: { strength: .35 } },
            { label: ".5", set: { strength: .5 } },
            { label: ".8", set: { strength: .8 } }
        ] },
        { label: "thickness", options: [
            { label: "1", set: { thickness: 1 } },
            { label: "2", set: { thickness: Style.space1 / 2 } }
        ] },
        { label: "colour", options: [
            { label: "muted", set: { lineColor: Style.textMuted } },
            { label: "band", set: { lineColor: Style.band } }
        ] },
        { label: "inset", options: [
            { label: "none", set: { inset: 0 } },
            { label: "space3", set: { inset: Style.space3 } },
            { label: "card", set: { inset: Style.notificationDividerInset } }
        ] }
    ]
}
