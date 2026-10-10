import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""

    implicitWidth: Style.controlWidth
    implicitHeight: column.implicitHeight
    color: Style.background

    Column {
        id: column
        anchors.centerIn: parent
        width: Style.controlWidth
        spacing: Style.space3

        Prose {
            width: parent.width
            text: "Displays"
        }
        Divider {
            width: parent.width
            inset: Style.space3
        }
        Prose {
            width: parent.width
            text: "Inputs"
        }
    }

    readonly property var controls: []
}
