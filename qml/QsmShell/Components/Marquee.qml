import QtQuick

import qs.QsmShell.Style

// Text longer than the room it has, made readable without being made annoying.
//
// The default is `once`, and the reasoning is the whole component: an ellipsis
// hides the end of a title forever, and a title scrolling forever is motion in
// the corner of an eye that is trying to work. Scrolling ONCE when the text
// changes shows the whole thing at the exact moment it is new — which is when
// a person wants it — and then rests as plain elided text.
//
// A surface where reading the text IS the task (a now-playing panel someone
// opened deliberately) sets `always`. A dense one sets `hover`. `never` is an
// ellipsis, kept as a mode so a call site can turn the motion off without
// swapping the component out.
Item {
    id: root

    property string text: ""
    // once | always | hover | never
    property string mode: "once"
    property string role: "label"
    property color color: Style.text
    // How long it holds still at each end. Without a pause the text arrives
    // and leaves in the same movement and neither end can be read.
    property int dwell: Motion.large * 2

    readonly property bool overflows: label.implicitWidth > width
    readonly property real _travel: Math.max(0, label.implicitWidth - width)
    readonly property bool _wanted: root.overflows && root.mode !== "never"
        && (root.mode === "always" || (!Style.reducedMotion
            && ((root.mode === "hover" && hover.hovered) || run.pending)))

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    clip: true

    QtObject {
        id: run
        // `once` arms on every text change and disarms when the pass ends.
        property bool pending: false
    }

    onTextChanged: {
        label.x = 0
        if (root.mode === "once") run.pending = true
    }
    onModeChanged: label.x = 0

    Prose {
        id: label
        role: root.role
        color: root.color
        text: root.text
        width: root.width
        // While it is travelling the text must be whole; at rest an ellipsis
        // is the honest mark for "there is more".
        elide: root._wanted ? Text.ElideNone : Text.ElideRight
    }

    HoverHandler { id: hover }

    SequentialAnimation {
        running: root._wanted && root._travel > 0
        loops: root.mode === "always" ? Animation.Infinite : 1
        onFinished: run.pending = false
        onRunningChanged: if (!running) label.x = 0

        PauseAnimation { duration: root.dwell }
        NumberAnimation {
            target: label
            property: "x"
            from: 0
            to: -root._travel
            // The pace is the text's length, not a fixed duration: a long
            // title and a short one must scroll at the same READING speed.
            duration: Math.max(Motion.large, root._travel * 16)
            easing.type: Motion.moveEasing
        }
        PauseAnimation { duration: root.dwell }
        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: Motion.medium
            easing.type: Motion.moveEasing
        }
    }
}
