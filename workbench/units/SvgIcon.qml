pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string name: "rain"

    readonly property color foreground: {
        switch (root.variant) {
        case "selected": return Style.accent;
        case "danger": return Style.danger;
        case "disabled": return Style.disabled(Style.text);
        default: return Style.text;
        }
    }

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    // The glyph carries no pointer and no state of its own: its colour and size
    // belong to the host. The whole icon scale is shown at once.
    RowLayout {
        anchors.centerIn: parent
        spacing: Style.space4

        Repeater {
            id: ladder
            model: [Style.iconXs, Style.iconSm, Style.iconMd, Style.iconLg, Style.iconXl, Style.iconXxl]

            SvgIcon {
                required property int modelData
                Layout.alignment: Qt.AlignVCenter
                name: root.name
                size: modelData
                color: root.foreground
            }
        }
    }

    function glyph(index: int): SvgIcon {
        return ladder.itemAt(index) as SvgIcon
    }

    readonly property var controls: [
        { label: "name", options: [
            { label: "battery", set: { name: "battery-full" } },
            { label: "wifi", set: { name: "wifi" } },
            { label: "cloud", set: { name: "cloud" } },
            { label: "rain", set: { name: "rain" } },
            { label: "snow", set: { name: "snow" } },
            { label: "fog", set: { name: "fog" } },
            { label: "empty", set: { name: "" } }
        ] },
        { label: "foreground", options: [
            { label: "rest", set: { variant: "rest" } },
            { label: "selected", set: { variant: "selected" } },
            { label: "danger", set: { variant: "danger" } },
            { label: "disabled", set: { variant: "disabled" } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            name: () => root.glyph(0).name,
            sizes: () => Array.from({ length: ladder.count }, (_, i) => root.glyph(i).width),
            ready: () => Array.from({ length: ladder.count }, (_, i) => root.glyph(i).ready).every(r => r)
        },
        runAction: () => false
    })
}
