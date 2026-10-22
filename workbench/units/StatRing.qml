import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property real fraction: 0.42
    property bool measured: true
    readonly property string reading: root.measured ? Math.round(root.fraction * 100) + "%" : ""
    property string caption: "CPU"
    property string glyph: "cpu"
    property string preset: "md"
    property bool open: true

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    StatRing {
        id: ring
        anchors.centerIn: parent
        size: root.preset
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
        { label: "size", options: [
            { label: "sm", set: { preset: "sm" } },
            { label: "md", set: { preset: "md" } },
            { label: "lg", set: { preset: "lg" } }
        ] },
        { label: "content", options: [
            { label: "full", set: { measured: true, caption: "CPU", glyph: "cpu" } },
            { label: "long", set: { measured: true, caption: "Package manager", glyph: "cpu" } },
            { label: "reading-only", set: { measured: true, caption: "", glyph: "" } },
            { label: "bare", set: { measured: false, caption: "", glyph: "" } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            value: () => ring.value,
            // The fraction on screen, which eases to the value.
            shown: () => ring._shown,
            reading: () => ring.reading,
            label: () => ring.label,
            "start-angle": () => ring.startAngle,
            "sweep-angle": () => ring.sweepAngle,
            diameter: () => ring.width,
            "reading-size": () => ring.readingSize,
            "accessible-name": () => ring.Accessible.name
        }
    })
}
