import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var series: [12, 18, 14, 26, 31, 24, 38, 44, 36, 52, 47, 61]
    property bool filled: variant === "area"
    property real floor: NaN
    property real ceiling: NaN
    property real stroke: 0
    property string preset: "md"

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    Sparkline {
        id: line
        anchors.centerIn: parent
        values: root.series
        area: root.filled
        minimum: root.floor
        maximum: root.ceiling
        thickness: root.stroke
        size: root.preset
    }

    readonly property var controls: [
        { label: "series", options: [
            { label: "empty", set: { series: [] } },
            { label: "one-point", set: { series: [40] } },
            { label: "climbing", set: { series: [12, 18, 14, 26, 31, 24, 38, 44, 36, 52, 47, 61] } },
            { label: "settled", set: { series: [40, 44, 38, 42, 41, 39, 43, 40, 42, 41] } },
            { label: "spiking", set: { series: [8, 9, 10, 96, 12, 11, 13, 88, 14, 12, 11, 10] } }
        ] },
        { label: "fill", options: [
            { label: "area", set: { filled: true } },
            { label: "line", set: { filled: false } }
        ] },
        { label: "extent", options: [
            { label: "auto", set: { floor: NaN, ceiling: NaN } },
            { label: "pinned", set: { floor: 0, ceiling: 100 } }
        ] },
        { label: "weight", options: [
            { label: "derived", set: { stroke: 0 } },
            { label: "stated", set: { stroke: Style.space1 } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { preset: "sm" } },
            { label: "md", set: { preset: "md" } },
            { label: "lg", set: { preset: "lg" } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            series: () => line.values,
            area: () => line.area,
            "scale-min": () => line.minimum,
            "scale-max": () => line.maximum,
            "accessible-name": () => line.Accessible.name,
            "box": () => [line.width, line.height]
        }
    })
}
