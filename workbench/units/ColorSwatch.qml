import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property color sample: Style.warning
    property string reading: "#E8C58A"
    property bool empty: false
    property bool selected: false
    property real face: Style.size("Control", "md")
    property int clicks: 0

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    ColorSwatch {
        id: swatch
        anchors.centerIn: parent
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

    readonly property var controls: [
        { label: "sample", options: [
            { label: "pale", set: { empty: false, sample: Style.warning, reading: "#E8C58A" } },
            { label: "deep", set: { empty: false, sample: Style.accent, reading: "#C5A5E9" } },
            { label: "translucent", set: { empty: false, sample: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.2), reading: "20%" } },
            { label: "empty", set: { empty: true, sample: Style.textMuted, reading: "" } }
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
        keys: {
            "Space": () => { swatch.activate(); return true },
            "Enter": () => { swatch.activate(); return true }
        },
        observables: {
            selected: () => swatch.selected,
            empty: () => swatch.empty,
            reading: () => swatch.reading,
            enabled: () => swatch.enabled,
            clicks: () => root.clicks
        },
        runAction: name => {
            if (name !== "activate")
                return false
            swatch.activate()
            return true
        }
    })
}
