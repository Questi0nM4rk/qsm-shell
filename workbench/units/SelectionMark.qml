import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool shown: variant !== "hidden"
    property bool strong: false
    property bool dimmed: false

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.markHeight + Style.space4 * 2

    SelectionMark {
        id: mark
        anchors.verticalCenter: parent.verticalCenter
        x: Math.round((root.width - width) / 2)
        shown: root.shown
        strong: root.strong
        restOpacity: root.dimmed ? 0.35 : 1
    }

    readonly property var controls: [
        { label: "visibility", options: [
            { label: "shown", set: { shown: true } },
            { label: "hidden", set: { shown: false } }
        ] },
        { label: "emphasis", options: [
            { label: "normal", set: { strong: false } },
            { label: "strong", set: { strong: true } }
        ] },
        { label: "rest", options: [
            { label: "full", set: { dimmed: false } },
            { label: "dim", set: { dimmed: true } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            shown: () => mark.shown,
            strong: () => mark.strong,
            dimmed: () => root.dimmed
        }
    })
}
