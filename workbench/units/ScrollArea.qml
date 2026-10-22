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
    // A viewport three rows tall: the room a small rollout leaves a list.
    property bool compact: variant === "short"

    readonly property real _rowStep: Style.size("Control", "md")

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    ScrollArea {
        id: scroll
        x: Style.space4
        y: Style.space4
        width: root.compact && !scroll.vertical ? root._rowStep * 3 : root.width - Style.space4 * 2
        height: root.compact && scroll.vertical ? root._rowStep * 3 : root.height - Style.space4 * 2
        orientation: root.orientation
        fadeColor: Style.band
        fade: root.cues
        indicator: root.cues

        Repeater {
            model: root.rows

            Prose {
                id: row
                required property int index
                readonly property real step: scroll.vertical
                    ? root._rowStep : Style.controlWidth / 2

                x: scroll.vertical ? 0 : index * step
                y: scroll.vertical ? index * step : 0
                height: root._rowStep
                verticalAlignment: Text.AlignVCenter
                role: "label"
                text: "Scrollable row " + (index + 1)
            }
        }
    }

    readonly property var controls: [
        { label: "viewport", options: [
            { label: "full", set: { compact: false } },
            { label: "three rows", set: { compact: true } }
        ] },
        { label: "content", options: [
            { label: "overflowing", set: { rows: 16 } },
            { label: "fitting", set: { rows: 2 } }
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
        actions: ["to-start", "to-end", "focus"],
        targets: ({ viewport: () => scroll }),
        observables: {
            overflows: () => scroll.overflows,
            "at-start": () => scroll.vertical
                ? scroll.viewport.atYBeginning : scroll.viewport.atXBeginning,
            "at-end": () => scroll.vertical
                ? scroll.viewport.atYEnd : scroll.viewport.atXEnd,
            position: () => scroll.vertical ? scroll.viewport.contentY : scroll.viewport.contentX,
            extent: () => scroll.vertical ? scroll.height : scroll.width,
            "fade-start": () => scroll.startFade,
            "fade-end": () => scroll.endFade,
            focused: () => scroll.focused,
            rows: () => root.rows,
            cues: () => root.cues,
            compact: () => root.compact
        },
        runAction: name => {
            if (name === "to-start") {
                scroll.scrollToStart();
                return true;
            }
            if (name === "to-end") {
                scroll.scrollToEnd();
                return true;
            }
            if (name === "focus") {
                scroll.forceActiveFocus(Qt.TabFocusReason);
                return true;
            }
            return false;
        }
    })
}
