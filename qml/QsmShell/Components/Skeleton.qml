import QtQuick

import qs.QsmShell.Style

// The shape of content that has not arrived yet.
//
// Trigger, and it is narrow: use a skeleton when the layout is KNOWN before
// the data is — a list of rows, a card with a title and two lines. Then the
// surface does not jump when the data lands, and the wait is spent looking at
// where the answer will be rather than at a spinner in an empty box.
//
// When the shape is not known, a `Spinner` is honest and a skeleton is not: a
// placeholder promising three rows to a response that returns none has told
// the person something false and then taken it back.
//
// The promise is a height. A line occupies exactly the line box of the
// `Prose` role it stands in for (measured from a real one, never restated), so
// stacked lines with no gap between them are the height of the paragraph that
// replaces them, and the bar inside is one glyph tall, which is what text
// weighs. A block occupies the height of the control preset it stands in for.
Item {
    id: root

    // block | line
    property string shape: "block"
    // The `Prose` role a line stands in for.
    property string role: "label"
    // The last line of a paragraph is short. Passing a fraction here is what
    // stops three identical bars from reading as a barcode.
    property real fraction: 1
    // The control preset a block stands in for (the Control family).
    property string size: "md"

    readonly property bool _line: shape === "line"
    // The breath's low point: the share of its colour the bar keeps.
    readonly property real _trough: 0.5

    // The real line box, from a real text. Hidden, and never painted.
    Prose {
        id: measure
        role: root.role
        text: "M"
        visible: false
    }

    implicitHeight: _line ? measure.implicitHeight : Style.size("Skeleton", size)
    // An intrinsic width, NOT one taken from the parent. Reading the parent
    // collapses to zero inside any layout whose own width comes from its
    // children — which is most of them — and a placeholder with no width is a
    // placeholder that placeholds nothing. A call site that wants a fraction
    // of a known width states it: `Layout.preferredWidth: parent.width * .6`.
    implicitWidth: Style.controlWidth * Math.max(0, Math.min(1, fraction))

    // A placeholder announces nothing: the surface that is loading says so.
    Accessible.ignored: true

    Rectangle {
        id: bar
        objectName: "skeletonBar"
        width: parent.width
        height: root._line ? measure.font.pixelSize : parent.height
        y: Math.round((parent.height - height) / 2)
        radius: root._line ? Style.radiusPill : Style.radiusSm
        color: Style.overlay

        // It breathes rather than shimmers. A travelling highlight is a second
        // motion vocabulary for one idea, and on a surface already carrying a
        // rollout it competes with it.
        SequentialAnimation on opacity {
            running: root.visible
            loops: Animation.Infinite
            NumberAnimation { to: root._trough; duration: Motion.pulse / 2; easing.type: Motion.moveEasing }
            NumberAnimation { to: 1; duration: Motion.pulse / 2; easing.type: Motion.moveEasing }
        }
    }
}
