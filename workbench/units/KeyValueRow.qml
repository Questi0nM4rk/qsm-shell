import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string glyph: root.variant === "battery" ? "battery-full" : ""
    property string reading: "87%"
    property string status: "Charging"

    implicitWidth: Style.controlWidth
    implicitHeight: rows.implicitHeight
    color: Style.band

    Column {
        id: rows
        anchors.centerIn: parent
        width: Style.controlWidth
        spacing: Style.space1

        KeyValueRow {
            width: parent.width
            icon: root.glyph
            label: "Battery"
            value: root.reading
        }
        KeyValueRow {
            width: parent.width
            label: "State"
            value: root.status
        }
    }

    readonly property var controls: []
}
