import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property real fraction: 0.42
    property string reading: "42%"
    property string caption: "CPU"
    property string glyph: "cpu"
    property int box: Style.ringDiameter
    property bool open: true

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    StatRing {
        id: ring
        anchors.centerIn: parent
        diameter: root.box
        value: root.fraction
        reading: root.reading
        label: root.caption
        icon: root.glyph
        startAngle: root.open ? -225 : -90
        sweepAngle: root.open ? 270 : 360
    }

    readonly property var controls: [
        { label: "form", options: [
            { label: "open", set: { open: true } },
            { label: "closed", set: { open: false } }
        ] },
        { label: "value", options: [
            { label: "none", set: { fraction: 0 } },
            { label: "part", set: { fraction: 0.42 } },
            { label: "full", set: { fraction: 1 } }
        ] },
        { label: "diameter", options: [
            { label: "sm", set: { box: Style.controlHeightLg } },
            { label: "md", set: { box: Style.ringDiameter } },
            { label: "lg", set: { box: Style.controlWidth } }
        ] },
        { label: "content", options: [
            { label: "full", set: { reading: "42%", caption: "CPU", glyph: "cpu" } },
            { label: "reading-only", set: { reading: "42%", caption: "", glyph: "" } },
            { label: "bare", set: { reading: "", caption: "", glyph: "" } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            value: () => ring.value,
            reading: () => ring.reading,
            label: () => ring.label,
            "start-angle": () => ring.startAngle,
            "sweep-angle": () => ring.sweepAngle
        }
    })
}
