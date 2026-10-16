import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property real reading: variant === "low" ? 0.08 : 0.62
    property real floor: variant === "low" ? 0.2 : -1
    property real ceiling: -1
    property real weight: Style.trackThickness
    property bool tall: false

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    Meter {
        id: level
        anchors.centerIn: parent
        width: root.tall ? Style.controlHeightLg : Style.controlWidth
        height: root.tall ? Style.controlWidth : Style.trackThickness
        orientation: root.tall ? Qt.Vertical : Qt.Horizontal
        value: root.reading
        low: root.floor
        high: root.ceiling
        thickness: root.weight
    }

    readonly property var controls: [
        { label: "value", options: [
            { label: "empty", set: { reading: 0 } },
            { label: "low", set: { reading: 0.08 } },
            { label: "high", set: { reading: 0.86 } }
        ] },
        { label: "threshold", options: [
            { label: "none", set: { floor: -1, ceiling: -1 } },
            { label: "low", set: { floor: 0.2, ceiling: -1 } },
            { label: "high", set: { floor: -1, ceiling: 0.8 } }
        ] },
        { label: "axis", options: [
            { label: "horizontal", set: { tall: false } },
            { label: "vertical", set: { tall: true } }
        ] },
        { label: "weight", options: [
            { label: "thin", set: { weight: Style.sliderTrackThickness } },
            { label: "regular", set: { weight: Style.trackThickness } }
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
            value: () => level.value,
            "low-threshold": () => level.low,
            "high-threshold": () => level.high,
            orientation: () => level.orientation,
            enabled: () => level.enabled
        }
    })
}
