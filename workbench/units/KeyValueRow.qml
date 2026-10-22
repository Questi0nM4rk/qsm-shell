import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string glyph: root.variant === "battery" ? "battery-full" : ""
    property string reading: "87%"
    property string status: "Charging"
    property string batteryLabel: "Battery"
    property color readingColor: Style.text

    implicitWidth: Style.controlWidth
    implicitHeight: rows.implicitHeight
    color: Style.band

    Column {
        id: rows
        anchors.centerIn: parent
        width: Style.controlWidth
        spacing: Style.space1

        KeyValueRow {
            id: first
            width: parent.width
            icon: root.glyph
            label: root.batteryLabel
            value: root.reading
            valueColor: root.readingColor
        }
        KeyValueRow {
            id: second
            width: parent.width
            label: "State"
            value: root.status
        }
    }

    readonly property var controls: [
        { label: "glyph", options: [
            { label: "set", set: { glyph: "battery-full" } },
            { label: "cleared", set: { glyph: "" } }
        ] },
        { label: "label", options: [
            { label: "short", set: { batteryLabel: "Battery" } },
            { label: "long", set: { batteryLabel: "Remaining battery charge on the internal pack" } }
        ] },
        { label: "value", options: [
            { label: "short", set: { reading: "87%" } },
            { label: "long", set: { reading: "87% (about 3 hours 42 minutes remaining)" } }
        ] },
        { label: "value colour", options: [
            { label: "text", set: { readingColor: Style.text } },
            { label: "danger", set: { readingColor: Style.danger } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            "glyph-shown": () => first.icon.length > 0,
            "row-height": () => first.height,
            "plain-row-height": () => second.height,
            "row-width": () => first.width,
            value: () => first.value
        }
    })
}
