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
    // Forwarded to Prose, so the role decides the colour; `metadata` and
    // `supporting` are already muted.
    property bool muted: false
    // How long it holds still at each end. Without a pause the text arrives
    // and leaves in the same movement and neither end can be read.
    property int dwell: Motion.readingDwell

    readonly property bool overflows: label.implicitWidth > width
    // Whether the text is moving now, and how far left of rest it has got.
    readonly property bool travelling: pass.running
    readonly property real offset: -label.x
    readonly property real _travel: Math.max(0, label.implicitWidth - width)
    readonly property var _modes: ["once", "always", "hover", "never"]
    // Reduced motion rests every mode as an ellipsis: a loop calms by getting
    // slower, and a scrolling title has no slower form that is still readable.
    // The pointer still reaches the rest of the text: under reduced motion a
    // hover PLACES it at the far end, with no travel, and leaving puts it back.
    readonly property bool _peek: Style.reducedMotion && root.overflows
        && root.mode !== "never" && hover.hovered
    readonly property bool _wanted: root.overflows && root.mode !== "never"
        && !Style.reducedMotion
        && (root.mode === "always"
            || (root.mode === "hover" && hover.hovered) || run.pending)

    // A constant: a long title scrolls inside the clip and never widens the
    // control; the host sets `width` for any other room.
    implicitWidth: Style.controlWidth
    implicitHeight: label.implicitHeight
    clip: true

    // One name for the whole line, whatever part of it is on screen.
    Accessible.role: Accessible.StaticText
    Accessible.name: root.text

    QtObject {
        id: run
        // `once` arms on every text change and disarms when the pass ends.
        property bool pending: false
        // Text that fits never plays a pass, so nothing would clear the flag
        // and a later resize would play a pass nobody asked for. The label has
        // its new width by the time this runs.
        function arm(): void {
            pending = root.mode === "once" && root.overflows
        }
    }

    // QML cannot throw out of a binding, so an unknown mode says so loudly
    // instead of passing for a deliberate `never`.
    function _checkMode(): void {
        if (_modes.indexOf(mode) < 0)
            console.error(`Marquee: unknown mode "${mode}" -- expected once, always, hover or never`)
    }
    Component.onCompleted: _checkMode()

    onTextChanged: {
        settle.stop()
        label.x = 0
        Qt.callLater(run.arm)
    }
    onModeChanged: {
        _checkMode()
        settle.stop()
        label.x = 0
    }

    Prose {
        id: label
        role: root.role
        muted: root.muted
        text: root.text
        width: root.width
        // While it is travelling the text must be whole; at rest an ellipsis
        // is the honest mark for "there is more".
        elide: root._wanted || root._peek ? Text.ElideNone : Text.ElideRight
        Accessible.ignored: true
    }

    HoverHandler { id: hover }

    Binding {
        target: label
        property: "x"
        value: -root._travel
        when: root._peek
    }

    NumberAnimation {
        id: settle
        target: label
        property: "x"
        to: 0
        duration: Motion.medium
        easing.type: Motion.moveEasing
    }

    SequentialAnimation {
        id: pass
        running: root._wanted && root._travel > 0
        loops: root.mode === "always" ? Animation.Infinite : 1
        onFinished: run.pending = false
        onRunningChanged: {
            if (running || label.x === 0) return
            // Stopped mid-pass (the pointer left, the text began to fit):
            // come back from where it is. Under reduced motion no position
            // animation runs, so it is placed.
            if (Style.reducedMotion) label.x = 0
            else settle.restart()
        }

        PauseAnimation { duration: root.dwell }
        NumberAnimation {
            target: label
            property: "x"
            from: 0
            to: -root._travel
            // The pace is the text's length, not a fixed duration: a long
            // title and a short one must scroll at the same READING speed,
            // and constant motion is linear. An ease-in-out ramped the speed
            // from 0 to twice the pace within one pass (0.1 to 5.9 px a
            // 50 ms step at a 3.1 px mean), so the words sped up as they
            // were being read.
            duration: Math.max(Motion.large, root._travel * Motion.readingPace)
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: root.dwell }
        NumberAnimation {
            target: label
            property: "x"
            to: 0
            // Back at the pace it came: a rewind far faster than the reading
            // pass is the text being yanked home.
            duration: Math.max(Motion.medium, root._travel * Motion.readingPace)
            easing.type: Easing.Linear
        }
    }
}
