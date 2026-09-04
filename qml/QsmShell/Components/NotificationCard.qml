pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// Consumer-owned notification/data card.
//
// All display data (title/body/source/icon), the accent/danger tint, and the
// action controls placed in the `actions` slot — plus their activation — are
// injected by the consumer. The card owns no notification-service or
// desktop-centre policy and renders no fixed notification model shape.
Item {
    id: root

    property string title: ""
    property string body: ""
    property string source: ""
    property string icon: ""
    property color accent: Style.accent
    property bool danger: false
    property bool selected: false
    property bool expanded: false
    // Consumer-owned action controls (placed here by the consumer).
    default property alias actions: actionHost.data

    signal dismissed

    implicitWidth: Style.notificationWidth
    implicitHeight: expanded ? headline.height + details.implicitHeight + Style.space2 : headline.height

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: headline.verticalCenter
        width: root.selected ? Style.markThickness + Style.spaceTight : Style.markThickness
        height: Style.markHeight
        radius: width / 2
        color: root.danger ? Style.danger : root.accent
    }
    RowLayout {
        id: headline
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        height: Style.notificationCollapsedHeight
        spacing: Style.space2
        SvgIcon { visible: root.icon.length > 0; name: root.icon; size: Style.iconSm; color: Style.textMuted }
        Text { visible: root.source.length > 0; text: root.source; color: Style.textMuted; font.pixelSize: Style.textXs }
        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.title
            textFormat: Text.PlainText
            color: Style.text
            font.pixelSize: Style.textMd
            font.weight: Style.weightBold
        }
    }
    // Expansion toggle sits behind the actionable content so a action click is
    // never toggled/stolen by the full-card expansion handler.
    StateLayer {
        anchors.fill: parent
        target: null
        onClicked: root.expanded = !root.expanded
    }
    ColumnLayout {
        id: details
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headline.bottom
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        visible: root.expanded
        spacing: Style.space2
        Text {
            Layout.fillWidth: true
            visible: root.body.length > 0
            text: root.body
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: Style.textMuted
            font.pixelSize: Style.textSm
        }
        RowLayout {
            id: actionHost
            Layout.fillWidth: true
            spacing: Style.space2
        }
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.MiddleButton; onClicked: root.dismissed() }
}
