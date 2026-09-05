pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Style

RowLayout {
    id: root
    required property var labels
    property int currentIndex: 0
    property bool compact: false
    signal selected(int index)
    spacing: Style.space2
    Repeater {
        model: root.labels
        delegate: Item {
            id: tab
            required property string modelData
            required property int index
            Layout.fillWidth: true
            implicitHeight: root.compact ? 36 : 48
            Rectangle { anchors.fill: parent; radius: Style.radiusSm; color: root.currentIndex === tab.index ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, .12) : "transparent" }
            Text { anchors.centerIn: parent; text: tab.modelData; color: root.currentIndex === tab.index ? Style.text : Style.textMuted; font.family: Style.fontFamily; font.pixelSize: root.compact ? Style.textXs : Style.textSm; font.weight: root.currentIndex === tab.index ? Style.weightBold : Style.weightMedium }
            StateLayer {
                anchors.fill: parent
                target: null
                focused: root.currentIndex === tab.index && root.activeFocus
                focusRadius: Style.radiusSm
                hoverScale: 1
                pressScale: .98
                onClicked: root.selected(tab.index)
            }
        }
    }
}
