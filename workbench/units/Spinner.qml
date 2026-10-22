import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property bool running: root.variant !== "stopped"
    property bool shown: true
    property int size: Style.iconLg

    implicitWidth: spinner.width
    implicitHeight: spinner.height
    color: Style.band

    Spinner {
        id: spinner
        anchors.centerIn: parent
        size: root.size
        running: root.running
        visible: root.shown
        accessibleName: "Scanning for devices"
    }

    readonly property var controls: [
        // A still image cannot show whether the mark turns.
        { label: "motion", options: [
            { label: "running", set: { running: true } },
            { label: "stopped", set: { running: false } }
        ] },
        // A surface that is hidden but not destroyed must not keep turning.
        { label: "surface", options: [
            { label: "shown", set: { shown: true } },
            { label: "hidden", set: { shown: false } }
        ] },
        // The icon scale: the stroke keeps its proportion at every step.
        { label: "size", options: [
            { label: "xs", set: { size: Style.iconXs } },
            { label: "sm", set: { size: Style.iconSm } },
            { label: "md", set: { size: Style.iconMd } },
            { label: "lg", set: { size: Style.iconLg } },
            { label: "xl", set: { size: Style.iconXl } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            running: () => spinner.running,
            turning: () => spinner.turning,
            size: () => spinner.size
        }
    })
}
