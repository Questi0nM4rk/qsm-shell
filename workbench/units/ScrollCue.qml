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
    property int orientation: Qt.Vertical
    // A viewport a few rows tall: the room a small rollout leaves a list.
    property bool compact: variant === "short"

    readonly property bool vertical: orientation === Qt.Vertical
    readonly property real _rowStep: Style.size("Control", "md")
    readonly property real _colStep: Style.controlWidth / 2

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    ListView {
        id: list
        x: Style.space4
        y: Style.space4
        width: root.compact && !root.vertical ? root._colStep * 3 : root.width - Style.space4 * 2
        height: !root.vertical ? root._rowStep
            : root.compact ? root._rowStep * 3 : root.height - Style.space4 * 2
        orientation: root.vertical ? ListView.Vertical : ListView.Horizontal
        clip: true
        model: root.rows
        boundsBehavior: Flickable.StopAtBounds

        delegate: Prose {
            required property int index
            width: root.vertical ? ListView.view.width : root._colStep
            height: root._rowStep
            verticalAlignment: Text.AlignVCenter
            role: "label"
            text: "Cue row " + (index + 1)
        }
    }

    ScrollCue {
        id: cue
        view: list
        orientation: root.orientation
        fadeColor: Style.band
        fade: root.fade
        indicator: root.indicator
    }

    readonly property var controls: [
        { label: "viewport", options: [
            { label: "full", set: { compact: false } },
            { label: "three rows", set: { compact: true } }
        ] },
        { label: "axis", options: [
            { label: "vertical", set: { orientation: Qt.Vertical } },
            { label: "horizontal", set: { orientation: Qt.Horizontal } }
        ] },
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
        actions: ["to-start", "to-end"],
        targets: ({ list: () => list }),
        observables: {
            overflows: () => cue.overflows,
            fade: () => cue.fade,
            indicator: () => cue.indicator,
            "fade-start": () => cue.startFade,
            "fade-end": () => cue.endFade,
            "at-start": () => root.vertical ? list.atYBeginning : list.atXBeginning,
            "at-end": () => root.vertical ? list.atYEnd : list.atXEnd,
            rows: () => root.rows,
            compact: () => root.compact,
            "view-extent": () => root.vertical ? list.height : list.width
        },
        runAction: name => {
            if (name === "to-start")
                list.positionViewAtBeginning();
            else if (name === "to-end")
                list.positionViewAtEnd();
            else
                return false;
            return true;
        }
    })
}
