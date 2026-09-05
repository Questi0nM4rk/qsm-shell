import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// A named value on one line: the label recedes, the value is read.
RowLayout {
    id: root

    required property string label
    required property string value
    property string icon: ""
    property color valueColor: Style.text

    spacing: Style.space2

    SvgIcon {
        visible: root.icon.length > 0
        name: root.icon
        size: Style.iconSm
        color: Style.textMuted
    }
    Prose {
        Layout.fillWidth: true
        role: "body"
        muted: true
        text: root.label
    }
    Prose {
        role: "reading"
        color: root.valueColor
        text: root.value
    }
}
