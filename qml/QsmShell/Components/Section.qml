import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// A named group of things, with the group's own action beside its name.
//
// The action lives on the HEADING, not at the bottom of the group: it acts on
// the group, so it belongs where the group is named. Putting it after the rows
// makes it read as acting on the last one.
ColumnLayout {
    id: root

    Accessible.role: Accessible.Grouping
    Accessible.name: root.title

    property string title: ""
    // The group's own action. Empty takes no space.
    property alias action: actionHost.data
    // The rows.
    default property alias content: bodyHost.data
    property real bodySpacing: Style.space1

    // The group owns the rhythm INSIDE it: its rows hang from the heading. The
    // space before a section is the owning surface's business, because only it
    // knows what precedes the group.
    spacing: Style.space1

    RowLayout {
        Layout.fillWidth: true
        visible: root.title.length > 0 || actionHost.children.length > 0
        spacing: Style.space2

        Prose {
            Layout.fillWidth: true
            role: "section"
            text: root.title
        }
        RowLayout {
            id: actionHost
            Layout.alignment: Qt.AlignVCenter
            spacing: Style.space1
        }
    }

    ColumnLayout {
        id: bodyHost
        Layout.fillWidth: true
        spacing: root.bodySpacing
    }
}
