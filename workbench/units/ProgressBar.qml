import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property bool unknown: variant === "unknown"
    property real reading: 0.42

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    ProgressBar {
        id: bar
        anchors.centerIn: parent
        width: Style.controlWidth
        indeterminate: root.unknown
        value: root.reading
        accessibleName: "Copying files"
    }

    // What the bar paints, read from its own parts rather than echoed from the
    // properties the host handed it.
    function part(name: string): Item {
        return bar.children.find(child => child.objectName === name) ?? null
    }

    readonly property var controls: [
        // The value group has no effect while the mode is indeterminate: that
        // state has no total.
        { label: "mode", options: [
            { label: "determinate", set: { unknown: false } },
            { label: "indeterminate", set: { unknown: true } }
        ] },
        { label: "value", options: [
            { label: "empty", set: { reading: 0 } },
            { label: "half", set: { reading: 0.5 } },
            { label: "full", set: { reading: 1 } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            indeterminate: () => bar.indeterminate,
            value: () => bar.value,
            enabled: () => bar.enabled,
            // The painted fill as a share of the track, to two decimals.
            "fill-share": () => Math.round(root.part("progressFill").width / bar.width * 100) / 100,
            // Whether the unknown-work band is on screen.
            sweeping: () => root.part("progressSweep").visible,
            description: () => bar.Accessible.description
        }
    })
}
