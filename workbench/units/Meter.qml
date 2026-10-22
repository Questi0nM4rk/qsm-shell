import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property real reading: variant === "low" ? 0.08 : 0.62
    property real floor: variant === "low" ? 0.2 : -1
    property real ceiling: -1
    property bool tall: false

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    Meter {
        id: level
        anchors.centerIn: parent
        width: root.tall ? Style.trackThickness : Style.controlWidth
        height: root.tall ? Style.controlWidth : Style.trackThickness
        orientation: root.tall ? Qt.Vertical : Qt.Horizontal
        value: root.reading
        low: root.floor
        high: root.ceiling
        accessibleName: "Battery"
    }

    // The painted fill, read from the meter's own part.
    readonly property Item fillPart: level.children.find(child => child.objectName === "meterFill")

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
            enabled: () => level.enabled,
            breached: () => level.breached,
            // The painted fill as a share of the track along its axis, to two
            // decimals: what a person reads, not the value the host handed in.
            "fill-share": () => Math.round((level.vertical
                ? root.fillPart.height / level.height
                : root.fillPart.width / level.width) * 100) / 100,
            description: () => level.Accessible.description
        }
    })
}
