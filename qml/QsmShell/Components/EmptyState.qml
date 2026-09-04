import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Style

ColumnLayout {
    id: root
    required property string title
    property string detail: ""
    property string icon: ""
    spacing: Style.space2
    SvgIcon { Layout.alignment: Qt.AlignHCenter; visible: root.icon.length > 0; name: root.icon; size: Style.iconLg; color: Style.textMuted }
    Text { Layout.alignment: Qt.AlignHCenter; text: root.title; color: Style.text; font.family: Style.fontFamily; font.pixelSize: Tokens.typeMd; font.weight: Style.weightBold }
    Text { Layout.alignment: Qt.AlignHCenter; visible: root.detail.length > 0; text: root.detail; color: Style.textMuted; font.family: Style.fontFamily; font.pixelSize: Style.textSm; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
}
