import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string reading: "72"
    property string caption: variant === "cpu" ? "CPU" : "Load"
    property string suffix: "%"
    property string glyph: "cpu"
    property string direction: "up"
    property string welcome: "down"
    property string weight: "display"

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    Stat {
        id: stat
        anchors.centerIn: parent
        value: root.reading
        label: root.caption
        unit: root.suffix
        icon: root.glyph
        trend: root.direction
        good: root.welcome
        emphasis: root.weight
    }

    readonly property var controls: [
        { label: "value", options: [
            { label: "72", set: { reading: "72" } },
            { label: "empty", set: { reading: "" } },
            { label: "long", set: { reading: "123456789012345678" } }
        ] },
        { label: "trend", options: [
            { label: "none", set: { direction: "" } },
            { label: "up", set: { direction: "up" } },
            { label: "down", set: { direction: "down" } },
            { label: "flat", set: { direction: "flat" } }
        ] },
        { label: "good", options: [
            { label: "none", set: { welcome: "none" } },
            { label: "up", set: { welcome: "up" } },
            { label: "down", set: { welcome: "down" } }
        ] },
        { label: "emphasis", options: [
            { label: "display", set: { weight: "display" } },
            { label: "hero", set: { weight: "hero" } }
        ] },
        { label: "label", options: [
            { label: "named", set: { caption: "CPU", glyph: "cpu" } },
            { label: "long", set: { caption: "Package manager transactions per second", glyph: "cpu" } },
            { label: "bare", set: { caption: "", glyph: "" } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            value: () => stat.value,
            label: () => stat.label,
            trend: () => stat.trend,
            good: () => stat.good,
            emphasis: () => stat.emphasis,
            "accessible-name": () => stat.Accessible.name
        }
    })
}
