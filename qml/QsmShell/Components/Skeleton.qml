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
Rectangle {
    id: root

    // A block, or a line of text. `line` sizes itself off the type scale so a
    // placeholder for a label is the height of a label.
    // block | line
    property string shape: "block"
    // Which text role this stands in for, when `shape` is "line".
    property string role: "label"
    // The last line of a paragraph is short. Passing a fraction here is what
    // stops three identical bars from reading as a barcode.
    property real fraction: 1

    readonly property int _lineHeight: {
        switch (role) {
        case "hero": return Style.textHero;
        case "display": return Style.textDisplay;
        case "heading": return Style.textXl;
        case "title": return Style.textMd;
        case "metadata": return Style.textXs;
        default: return Style.textSm;
        }
    }

    implicitHeight: shape === "line" ? _lineHeight : Style.controlHeight
    // An intrinsic width, NOT one taken from the parent. Reading the parent
    // collapses to zero inside any layout whose own width comes from its
    // children — which is most of them — and a placeholder with no width is a
    // placeholder that placeholds nothing. A call site that wants a fraction
    // of a known width states it: `Layout.preferredWidth: parent.width * .6`.
    implicitWidth: Style.controlWidth * Math.max(0, Math.min(1, fraction))
    radius: shape === "line" ? height / 2 : Style.radiusSm
    color: Style.overlay

    // It breathes rather than shimmers. A travelling highlight is a second
    // motion vocabulary for one idea, and on a surface already carrying a
    // rollout it competes with it.
    SequentialAnimation on opacity {
        running: root.visible
        loops: Animation.Infinite
        NumberAnimation { to: 0.4; duration: Motion.pulse / 2; easing.type: Motion.moveEasing }
        NumberAnimation { to: 1; duration: Motion.pulse / 2; easing.type: Motion.moveEasing }
    }
}
