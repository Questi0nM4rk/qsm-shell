import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// The state a list is in most often before it is anything else. It says what
// belongs here, and -- when the consumer supplies one -- what to do about it.
//
// Spacing says what belongs together: the glyph, the title and its reading are
// one message and sit close; the way out is its own thing, a step clear of it.
// It is never wider than a control, so a long reading wraps instead of
// pushing past the surface that holds it.
ColumnLayout {
    id: root

    required property string title
    property string detail: ""
    property string icon: ""
    // The useful next action. An empty state that only apologises has told the
    // person nothing they can act on.
    default property alias action: actionHost.data

    spacing: 0

    Accessible.role: Accessible.Grouping
    Accessible.name: root.title
    Accessible.description: root.detail

    SvgIcon {
        Layout.alignment: Qt.AlignHCenter
        visible: root.icon.length > 0
        name: root.icon
        size: Style.iconLg
        color: Style.textMuted
    }
    Prose {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: Style.controlWidth
        Layout.topMargin: root.icon.length > 0 ? Style.space3 : 0
        role: "title"
        text: root.title
    }
    Prose {
        Layout.fillWidth: true
        Layout.maximumWidth: Style.controlWidth
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Style.space1
        visible: root.detail.length > 0
        role: "body"
        muted: true
        horizontalAlignment: Text.AlignHCenter
        text: root.detail
    }
    RowLayout {
        id: actionHost
        Layout.alignment: Qt.AlignHCenter
        // No gap for an empty host, or for one whose items are all hidden.
        Layout.topMargin: implicitHeight > 0 ? Style.space4 : 0
        spacing: Style.space2
    }
}
