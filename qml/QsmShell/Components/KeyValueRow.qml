import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Style

RowLayout {
    id: root
    required property string label
    required property string value
    property string icon: ""
    property color valueColor: Style.text
    spacing: Style.space2
    SvgIcon { visible: root.icon.length > 0; name: root.icon; size: Style.iconSm; color: Style.textMuted }
    Text { Layout.fillWidth: true; text: root.label; color: Style.textMuted; font.family: Style.fontFamily; font.pixelSize: Style.textSm }
    Text { text: root.value; color: root.valueColor; font.family: Style.technicalFontFamily; font.pixelSize: Style.textSm; font.weight: Style.weightBold }
}
