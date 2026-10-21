import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// The state a list is in most often before it is anything else. It says what
// belongs here, and -- when the consumer supplies one -- what to do about it.
ColumnLayout {
    id: root

    required property string title
    property string detail: ""
    property string icon: ""
    // The useful next action. An empty state that only apologises has told the
    // person nothing they can act on.
    default property alias action: actionHost.data

    spacing: Style.space2

    SvgIcon {
        Layout.alignment: Qt.AlignHCenter
        visible: root.icon.length > 0
        name: root.icon
        size: Style.iconLg
        color: Style.textMuted
    }
    Prose {
        Layout.alignment: Qt.AlignHCenter
        role: "title"
        text: root.title
    }
    Prose {
        Layout.fillWidth: true
        visible: root.detail.length > 0
        role: "body"
        muted: true
        horizontalAlignment: Text.AlignHCenter
        text: root.detail
    }
    RowLayout {
        id: actionHost
        visible: children.length > 0
        Layout.alignment: Qt.AlignHCenter
        spacing: Style.space2
    }
}
