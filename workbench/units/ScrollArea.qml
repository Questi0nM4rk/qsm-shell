import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property int rows: 16
    property int orientation: Qt.Vertical
    property bool cues: true

    color: Style.background
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    ScrollArea {
        id: scroll
        anchors.fill: parent
        anchors.margins: Style.space4
        orientation: root.orientation
        fade: root.cues
        indicator: root.cues

        Repeater {
            model: root.rows

            Prose {
                id: row
                required property int index
                readonly property real step: scroll.vertical
                    ? Style.controlHeight : Style.controlWidth / 2

                x: scroll.vertical ? 0 : index * step
                y: scroll.vertical ? index * step : 0
                role: "label"
                text: "Scrollable row " + (index + 1)
            }
        }
    }

    readonly property var controls: [
        { label: "content", options: [
            { label: "overflowing", set: { rows: 16 } },
            { label: "fitting", set: { rows: 4 } }
        ] },
        { label: "axis", options: [
            { label: "vertical", set: { orientation: Qt.Vertical } },
            { label: "horizontal", set: { orientation: Qt.Horizontal } }
        ] },
        { label: "chrome", options: [
            { label: "cues", set: { cues: true } },
            { label: "bare", set: { cues: false } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: ["to-start", "to-end", "settle"],
        observables: {
            overflows: () => scroll.overflows,
            "at-start": () => scroll.vertical
                ? scroll.viewport.atYBeginning : scroll.viewport.atXBeginning,
            "at-end": () => scroll.vertical
                ? scroll.viewport.atYEnd : scroll.viewport.atXEnd,
            rows: () => root.rows,
            cues: () => root.cues
        },
        runAction: name => {
            const view = scroll.viewport;
            if (name === "to-start") {
                if (scroll.vertical)
                    view.contentY = 0;
                else
                    view.contentX = 0;
                return true;
            }
            if (name === "to-end") {
                if (scroll.vertical)
                    view.contentY = view.contentHeight - view.height;
                else
                    view.contentX = view.contentWidth - view.width;
                return true;
            }
            if (name === "settle") {
                view.returnToBounds();
                return true;
            }
            return false;
        }
    })
}
