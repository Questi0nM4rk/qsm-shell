import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

Card {
    id: root

    property alias icon: icon.name
    property alias label: label.text
    property string detail: ""
    property color accentColor: Style.accent
    property bool active: false
    property bool compact: false
    signal clicked

    readonly property real padding: compact ? Style.space3 : Style.space4
    implicitHeight: compact ? Style.controlHeightSm : Style.controlHeight
    implicitWidth: content.implicitWidth + padding * 2
    radius: Style.radiusPill
    opacity: enabled ? 1 : Style.opacityDisabled
    surfaceColor: active
        ? Qt.tint(Style.surfaceRaised, Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.14))
        : Style.surface

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        spacing: Style.space2

        SvgIcon { id: icon; size: root.compact ? 16 : Style.iconMd }
        Text {
            id: label
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: root.compact ? Style.textXs : Style.textSm
            font.weight: Style.weightMedium
        }
        Text {
            visible: root.detail.length > 0
            text: root.detail
            color: root.accentColor
            font.family: Style.technicalFontFamily
            font.pixelSize: Style.textXs
            font.weight: Style.weightBold
        }
    }

    StateLayer {
        anchors.fill: parent
        interactive: root.enabled
        hoverScale: 1.04
        pressScale: 0.97
        onClicked: root.clicked()
    }
}
