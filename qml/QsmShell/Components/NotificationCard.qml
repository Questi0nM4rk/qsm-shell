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
    // Keyboard focus. Defaults to this item's own, so a control that takes
    // focus rings without wiring; a list that owns focus for its rows binds it.
    property bool focused: root.activeFocus
    // Consumer-owned action controls (placed here by the consumer).
    default property alias actions: actionHost.data

    signal dismissed

    implicitWidth: Style.notificationWidth
    implicitHeight: expanded ? headline.height + details.implicitHeight + Style.space2 : headline.height

    SelectionMark {
        anchors.left: parent.left
        anchors.verticalCenter: headline.verticalCenter
        shown: true
        strong: root.selected
        markColor: root.danger ? Style.danger : root.accent
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
        Prose { visible: root.source.length > 0; role: "metadata"; text: root.source }
        Prose { Layout.fillWidth: true; role: "title"; text: root.title }
    }
    // Expansion toggle sits behind the actionable content so a action click is
    // never toggled/stolen by the full-card expansion handler.
    StateLayer {
        anchors.fill: parent
        target: null
        focused: root.focused
        focusRadius: Style.radiusLg
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
        Prose {
            Layout.fillWidth: true
            visible: root.body.length > 0
            role: "body"
            muted: true
            text: root.body
        }
        RowLayout {
            id: actionHost
            Layout.fillWidth: true
            spacing: Style.space2
        }
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.MiddleButton; onClicked: root.dismissed() }
}
