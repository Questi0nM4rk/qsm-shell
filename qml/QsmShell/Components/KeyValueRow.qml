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
    implicitWidth: Style.controlWidth

    SvgIcon {
        objectName: "keyValueGlyph"
        visible: root.icon.length > 0
        name: root.icon
        size: Style.iconSm
        color: Style.textMuted
    }
    Prose {
        objectName: "keyValueLabel"
        Layout.fillWidth: true
        role: "label"
        muted: true
        text: root.label
    }
    Prose {
        objectName: "keyValueReading"
        role: "reading"
        color: root.valueColor
        text: root.value
    }
}
