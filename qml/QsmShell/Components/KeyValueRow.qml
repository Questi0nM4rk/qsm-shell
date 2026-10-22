import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// A named value on one line: the label recedes, the value is read.
//
// The two share the line: each takes the room its text asks for, and when the
// line is too short both give way together and elide, so a long reading never
// squeezes its own label down to a few letters. The height is one glyph step
// whether or not there is a glyph, so a column of rows keeps one rhythm.
RowLayout {
    id: root

    required property string label
    required property string value
    property string icon: ""
    property color valueColor: Style.text

    // Read as one phrase, not as two unrelated texts.
    Accessible.role: Accessible.StaticText
    Accessible.name: root.label + ": " + root.value

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
        // The row's height: one glyph step, glyph or not.
        Layout.preferredHeight: Style.iconSm
        verticalAlignment: Text.AlignVCenter
        role: "label"
        muted: true
        text: root.label
        Accessible.ignored: true
    }
    Prose {
        objectName: "keyValueReading"
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        role: "reading"
        color: root.valueColor
        text: root.value
        Accessible.ignored: true
    }
}
