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
    }

    readonly property var controls: [
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
            enabled: () => bar.enabled
        }
    })
}
