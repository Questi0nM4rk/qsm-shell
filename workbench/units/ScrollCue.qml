pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property int rows: 16
    property bool fade: true
    property bool indicator: true

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: Style.space4
        clip: true
        model: root.rows
        boundsBehavior: Flickable.StopAtBounds

        delegate: Prose {
            required property int index
            width: ListView.view.width
            height: Style.size("Control", "md")
            role: "label"
            text: "Cue row " + (index + 1)
        }
    }

    ScrollCue {
        id: cue
        view: list
        fadeColor: Style.band
        fade: root.fade
        indicator: root.indicator
    }

    readonly property var controls: [
        { label: "content", options: [
            { label: "overflowing", set: { rows: 16 } },
            { label: "fitting", set: { rows: 2 } }
        ] },
        { label: "fade", options: [
            { label: "on", set: { fade: true } },
            { label: "off", set: { fade: false } }
        ] },
        { label: "indicator", options: [
            { label: "on", set: { indicator: true } },
            { label: "off", set: { indicator: false } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            overflows: () => cue.overflows,
            fade: () => cue.fade,
            indicator: () => cue.indicator,
            rows: () => root.rows
        }
    })
}
