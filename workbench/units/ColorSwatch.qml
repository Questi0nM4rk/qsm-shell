import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property color sample: Style.warning
    property string reading: "Sand"
    property bool empty: false
    property bool selected: false
    property real face: Style.size("Control", "lg")
    property color ground: Style.band
    // A palette is the swatch as a dense picker row uses it: faces on the
    // pointer floor, one per colour, the host owning which is picked.
    property bool dense: false
    property int picked: 1
    property int clicks: 0

    readonly property var paletteColors: [Style.accent, Style.info, Style.success, Style.warning,
        Style.danger, "#2D1540"]

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: root.ground

    ColorSwatch {
        id: swatch
        anchors.centerIn: parent
        visible: !root.dense
        sample: root.empty ? Style.textMuted : root.sample
        empty: root.empty
        reading: root.reading
        size: root.face
        selected: root.selected
        onClicked: {
            root.clicks++
            root.eventRecorder?.("intent", "clicked", { empty: root.empty, selected: root.selected })
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        visible: root.dense
        spacing: Style.space1

        Repeater {
            id: swatches
            model: root.paletteColors

            ColorSwatch {
                required property int index
                required property color modelData
                sample: modelData
                size: Style.space5
                target: Style.space5
                selected: index === root.picked
                onClicked: {
                    root.picked = index
                    root.clicks++
                    root.eventRecorder?.("intent", "clicked", { index })
                }
            }
        }
    }

    readonly property var controls: [
        { label: "sample", options: [
            { label: "sand", set: { empty: false, sample: Style.warning, reading: "Sand" } },
            { label: "iris", set: { empty: false, sample: Style.accent, reading: "Iris" } },
            { label: "translucent", set: { empty: false, sample: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.2), reading: "20%" } },
            { label: "plum", set: { empty: false, sample: "#2D1540", reading: "Plum" } },
            { label: "empty", set: { empty: true, sample: Style.textMuted, reading: "" } }
        ] },
        { label: "ground", options: [
            { label: "band", set: { ground: Style.band } },
            { label: "surface", set: { ground: Style.surface } },
            { label: "overlay", set: { ground: Style.overlay } }
        ] },
        { label: "arrangement", options: [
            { label: "single", set: { dense: false } },
            { label: "palette", set: { dense: true } }
        ] },
        { label: "selection", options: [
            { label: "rest", set: { selected: false } },
            { label: "selected", set: { selected: true } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { face: Style.size("Control", "sm") } },
            { label: "md", set: { face: Style.size("Control", "md") } },
            { label: "lg", set: { face: Style.size("Control", "lg") } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        targets: ({
            scene: () => root,
            swatch: () => swatch,
            "palette-first": () => swatches.itemAt(0),
            "palette-second": () => swatches.itemAt(1),
            "palette-third": () => swatches.itemAt(2),
            "palette-last": () => swatches.itemAt(root.paletteColors.length - 1)
        }),
        keys: {
            "Space": () => { swatch.activate(); return true },
            "Enter": () => { swatch.activate(); return true }
        },
        observables: {
            selected: () => swatch.selected,
            empty: () => swatch.empty,
            reading: () => swatch.reading,
            enabled: () => swatch.enabled,
            contained: () => swatch.contained,
            "keyboard-focus": () => swatch.visualFocus,
            clicks: () => root.clicks,
            picked: () => root.picked,
            "palette-focus": () => {
                for (let i = 0; i < root.paletteColors.length; i++)
                    if (swatches.itemAt(i).visualFocus)
                        return i
                return -1
            }
        },
        runAction: name => {
            if (name !== "activate")
                return false
            swatch.activate()
            return true
        }
    })
}
