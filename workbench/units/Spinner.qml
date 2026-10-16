import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property bool running: root.variant !== "stopped"
    property int size: Style.iconLg

    implicitWidth: spinner.width
    implicitHeight: spinner.height
    color: Style.band

    Spinner {
        id: spinner
        anchors.centerIn: parent
        size: root.size
        running: root.running
    }

    readonly property var controls: [
        // A still image cannot show whether the mark turns, and nothing else
        // about a spinner varies.
        { label: "motion", options: [
            { label: "running", set: { running: true } },
            { label: "stopped", set: { running: false } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            running: () => spinner.running
        }
    })
}
