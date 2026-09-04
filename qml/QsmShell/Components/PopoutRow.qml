import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// Value row with an optional trailing action.
Item {
    id: root
    required property string icon
    required property string label
    property string value: ""
    property bool active: false
    property string badgeIcon: ""
    property bool selectable: true
    property string actionIcon: ""
    property bool actionDanger: false
    readonly property bool hovered: row.hovered
    signal clicked
    signal actionTriggered

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    MenuRowItem {
        id: row
        anchors.fill: parent
        icon: root.icon
        primary: root.label
        selected: root.active
        disabled: !root.selectable

        content: RowLayout {
            spacing: Style.space2
            SvgIcon { visible: root.badgeIcon.length > 0; name: root.badgeIcon; size: Style.iconXs; color: Style.textMuted }
            Text {
                visible: root.value.length > 0
                text: root.value
                color: Style.textMuted
                font.family: /\d/.test(root.value) ? Style.technicalFontFamily : Style.fontFamily
                font.pixelSize: Style.textXs
            }
            IconButton {
                visible: root.actionIcon.length > 0
                icon: root.actionIcon
                size: 16
                padding: Tokens.space1
                color: root.hovered && root.actionDanger ? Style.danger : Style.textMuted
                opacity: root.hovered ? 1 : Style.opacityDisabled
                onClicked: root.actionTriggered()
                Behavior on opacity { NumberAnimation { duration: Motion.micro } }
            }
        }

        onActivated: root.clicked()
    }
}
